# -*- encoding : UTF-8 -*-
class Document
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Paperclip

  field :content_file_name
  field :content_file_type
  field :content_file_size,  type: Integer
  field :content_updated_at, type: Time
  field :content_text,       type: String,  default: ""
  field :is_an_original,     type: Boolean, default: false
  field :is_an_upload,       type: Boolean, default: false
  field :tags,               type: String,  default: ""
  field :position,           type: Integer
  field :dirty,              type: Boolean, default: true
  field :token,              type: String

  references_many :document_tags, dependent: :destroy
  references_many :remote_files, as: :remotable, dependent: :destroy
  referenced_in :pack

  has_mongoid_attached_file :content,
                            styles: {
                                thumb: ["46x67>", :png],
                                medium: ["92x133", :png]
                            },
                            path: ":rails_root/files/#{Rails.env.test? ? 'test_' : ''}attachments/documents/:id/:style/:filename",
                            url: "/account/documents/:id/download/:style"

  before_content_post_process do |image|
    if image.dirty # halts processing
      false
    else
      true
    end
  end

  after_create :split_pages, :add_tags
  after_create :generate_thumbs!, :extract_content!, unless: Proc.new { |d| d.is_an_original || Rails.env.test? }

  scope :without_original, where:  { :is_an_original.in => [false, nil] }
  scope :originals,        where:  { is_an_original: true }

  scope :not_extracted,    where:  { content_text: "" }
  scope :extracted,        not_in: { content_text: [""] }
  scope :cannot_extract,   where:  { content_text: "-[none]" }

  scope :not_clean,        where:  { dirty: true }
  scope :clean,            where:  { dirty: false }

  scope :uploaded,         where:  { is_an_upload: true }
  scope :scanned,          where:  { is_an_upload: false }

  scope :of_month, lambda { |time| where(created_at: { '$gt' => time.beginning_of_month, '$lt' => time.end_of_month }) }

  def get_token
    if token.present?
      token
    else
      update_attribute(:token, rand(36**50).to_s(36))
      token
    end
  end

  def get_access_url(style=:original)
    content.url(style) + "&token=" + get_token
  end

  def get_remote_file(user,service_name)
    remote_file = remote_files.of(user,service_name).first
    unless remote_file
      remote_file = RemoteFile.new
      remote_file.user = user
      remote_file.remotable = self
      remote_file.pack = self.pack
      remote_file.service_name = service_name
      remote_file.save
    end
    remote_file
  end

  protected

  def split_pages
    if self.is_an_original
      temp_file = content.queued_for_write[:original]
      temp_path = File.expand_path(temp_file.path)
      nbr = File.basename(self.content_file_name, ".pdf")
      system "pdftk #{temp_path} burst output /tmp/#{nbr}_pages_%03d.pdf"

      # FIXME use better regex
      Dir.glob("/tmp/#{nbr}_*").sort.each_with_index do |file, index|
        document = Document.new
        document.dirty = true
        document.pack = self.pack
        document.position = index
        document.content = File.new file
        document.is_an_upload = self.is_an_upload
        document.save
      end
    end
  end

  def add_tags
    self.pack.users.each do |user|
      document_tag = DocumentTag.new
      document_tag.document = self
      document_tag.pack = self.pack
      document_tag.user = user
      document_tag.generate
      document_tag.save
    end
  end

  public

  class << self
    def by_position
      asc(:position)
    end

    def search_ids_by_contents(contents)
      search_by_contents(contents).distinct(:_id)
    end

    def search_by_contents(contents)
      queries = contents.split(' ').map { |e| /#{e}/i }
      all_in(content_text: queries)
    end

    def search_ids_by_tags(tags)
      queries = tags.split(' ').map { |e| /#{e}/i }
      document_ids = self.all.distinct(:_id)
      document_tags = DocumentTag.any_in(document_id: document_ids).all_in(name: queries)
      document_tags.distinct(:document_id)
    end

    def search_by_tags(tags)
      any_in(_id: search_ids_by_tags(tags))
    end

    def search_for(contents)
      ids = []
      contents.split(' ').each_with_index do |content,index|
        temp_ids = search_ids_by_contents(content) + search_ids_by_tags(content)
        if index != 0
          ids = temp_ids.select { |e| e.in? ids }
        else
          ids = temp_ids
        end
      end
      any_in(_id: ids)
    end

    def update_file pack, filename, is_an_upload=false
      start_at_page = pack.documents.size
      temp_path = pack.original_document.content.path
      basename = File.basename(temp_path,".pdf")
      system "pdftk #{filename} burst output #{basename}_pages_%03d.pdf_"
      rename_pages start_at_page
      add_pages pack, basename, start_at_page, is_an_upload
      update_original_file temp_path, filename
    end

    def rename_pages start_at_page
      Dir.glob("*_pages*").each_with_index do |file,index|
        number = (start_at_page + index).to_s
        new_name = file.sub /[0-9]{3}\.pdf_/, "0" * (3 - number.size) + number + ".pdf"
        File.rename file, new_name
      end
    end

    def add_pages pack, basename, start_at_page, is_an_upload
      Dir.glob("#{basename}_pages*").sort.each_with_index do |file, index|
        document = Document.new
        document.dirty = true
        document.pack = pack
        document.position = start_at_page + index
        document.content = File.new file
        document.is_an_upload = is_an_upload
        document.save
        File.delete file
      end
    end

    def update_original_file temp_path, filename
      File.rename temp_path, temp_path + "_"
      system "pdftk A=#{temp_path}_ B=#{filename} cat A B output #{temp_path}"
      system "rm #{temp_path}_ #{filename}"
      system "cp #{temp_path} ./"
    end
  end

  def generate_thumbs!
    self.dirty = false # set to false before reprocess to pass `before_content_post_process`
    self.content.reprocess!
    save
  end
  handle_asynchronously :generate_thumbs!, queue: 'documents thumbs', priority: 0

  def extract_content!
    if self.content.queued_for_write[:original]
      path = self.content.queued_for_write[:original].path
    else
      path = self.content.path
    end
    receiver = Receiver.new
    result = PDF::Reader.file(path,receiver) rescue false
    if result
      self.content_text = receiver.text.presence || "-[none]"
    else
      self.content_text = "-[none]"
    end
    if self.is_an_upload && self.content_text == "-[none]"
      imagepath = "#{Rails.root}/tmp/image.tif"
      system "convert -density 100 #{path} -colorspace Gray -depth 8 -alpha off #{imagepath}"
      tess = Tesseract::Process.new(imagepath, lang: :fra )
      words = tess.to_s.split(/\n/).join(' ').split(' ').uniq.select { |e| e.size > 1 }
      self.content_text = ''
      words.each do |word|
        if Dictionary.find_one(word)
          self.content_text += ' ' + word
        end
      end
      File.delete(imagepath)
      unless self.content_text.presence
        self.content_text = " "
      end
    end
    save
  end
  handle_asynchronously :extract_content!, queue: 'documents content', priority: 10
end

class Receiver
  attr_reader :text
  def initialize
    @text = ""
  end
  def show_text(string, *params)
    string.split().each do |dirty_word|
      word = dirty_word.scan(/[\w|.|@|_|-]+/).join().downcase
      if word.length > 1 and word.length <= 50
        if Dictionary.find_one(word)
          @text += " #{word}"
        end
      end
    end
  end
  def show_text_with_positioning(array, *params)
    show_text array.select { |element| element.is_a? String }.join()
  end
end

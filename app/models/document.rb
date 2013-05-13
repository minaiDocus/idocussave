# -*- encoding : UTF-8 -*-
class Document
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Paperclip
  include Tire::Model::Search
  include Tire::Model::Callbacks

  field :content_file_name
  field :content_file_type
  field :content_file_size,  type: Integer
  field :content_updated_at, type: Time
  field :content_text,       type: String,  default: ""
  field :is_an_original,     type: Boolean, default: false
  field :is_an_upload,       type: Boolean, default: false
  field :is_a_cover,         type: Boolean, default: false
  field :tags,               type: Array,   default: []
  field :position,           type: Integer
  field :dirty,              type: Boolean, default: true
  field :token,              type: String

  has_many :remote_files,  as: :remotable, dependent: :destroy
  belongs_to :pack

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

  before_create :init_tags
  after_create :split_pages
  after_create :generate_thumbs!, :extract_content!, unless: Proc.new { |d| d.is_an_original || Rails.env.test? }
  after_save :update_pack!

  scope :without_original, where:  { :is_an_original.in => [false, nil] }
  scope :originals,        where:  { is_an_original: true }

  scope :not_extracted,    where:  { content_text: "" }
  scope :extracted,        not_in: { content_text: [""] }
  scope :cannot_extract,   where:  { content_text: "-[none]" }

  scope :not_clean,        where:  { dirty: true }
  scope :clean,            where:  { dirty: false }

  scope :uploaded,         where:  { is_an_upload: true }
  scope :scanned,          where:  { is_an_upload: false }

  scope :covers,           where:  { is_a_cover: true }
  scope :not_covers,       any_in: { is_a_cover: [false, nil] }

  scope :of_month, lambda { |time| where(created_at: { '$gt' => time.beginning_of_month, '$lt' => time.end_of_month }) }

  mapping do
    indexes :id, as: 'stringified_id'
    indexes :pack_id
    indexes :created_at, type: 'date'
    indexes :tags
    indexes :content_file_name
    indexes :content_file_type
    indexes :content_text
    indexes :is_an_original, type: 'boolean'
    indexes :is_an_upload, type: 'boolean'
    indexes :is_a_cover, type: 'boolean'
    indexes :position, type: 'integer'
  end

  def self.search(query, params = {})
    tire.search(page: params[:page], per_page: params[:per_page], load: true) do
      filter :term, id: params[:id] if params[:id].present?
      filter :term, pack_id: params[:pack_id] if params[:pack_id].present?
      filter :term, is_an_original: params[:is_an_original] unless params[:is_an_original].nil?
      filter :term, is_an_upload: params[:is_an_upload] unless params[:is_an_upload].nil?
      filter :term, is_a_cover: params[:is_a_cover] unless params[:is_a_cover].nil?
      sort { by :position, 'asc' }
      query { string(query) } if query.present?
    end
  end

  def stringified_id
    self.id.to_s
  end

  def update_pack!
    if (self.content_text_changed? || (self.is_an_original && self.tags_changed?)) && pack.persisted?
      Pack.without_callback(:save, :after, :update_reporting_document) do
        pack.timeless.save
      end
    end
  end

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

  def get_tiff_file
    file_path = self.content.path
    temp_path = "/tmp/#{self.content_file_name.sub(/\.pdf$/,'.tiff')}"
    PdfDocument::Utils.generate_tiff_file(file_path, temp_path)
    temp_path
  end

  def get_remote_file(user,service_name,type='pdf')
    remote_file = remote_files.of(user,service_name).with_type(type).first
    remote_file ||= RemoteFile.new
    remote_file.user ||= user
    if type == 'pdf'
      remote_file.remotable ||= self
    elsif type == 'tiff'
      remote_file.temp_path = get_tiff_file
    end
    remote_file.pack ||= self.pack
    remote_file.service_name ||= service_name
    remote_file.save
    remote_file
  end

  def get_remote_files(user,service_name)
    current_remote_files = []
    if service_name == 'Dropbox Extended'
      if user.file_type_to_deliver.in? [ExternalFileStorage::ALL_TYPES, ExternalFileStorage::PDF, nil]
        current_remote_files << get_remote_file(user,service_name,'pdf')
      end
      if user.file_type_to_deliver.in? [ExternalFileStorage::ALL_TYPES, ExternalFileStorage::TIFF]
        current_remote_files << get_remote_file(user,service_name,'tiff')
      end
    else
      if user.external_file_storage.get_service_by_name(service_name).try(:file_type_to_deliver).in? [ExternalFileStorage::ALL_TYPES, ExternalFileStorage::PDF, nil]
        current_remote_files << get_remote_file(user,service_name,'pdf')
      end
      if user.external_file_storage.get_service_by_name(service_name).try(:file_type_to_deliver).in? [ExternalFileStorage::ALL_TYPES, ExternalFileStorage::TIFF]
        current_remote_files << get_remote_file(user,service_name,'tiff')
      end
    end
    current_remote_files
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

  public

  def init_tags
    self.tags = pack.name.downcase.sub(' all', '').split
    if !self.is_an_original && number
      self.tags << number
    end
  end

  def number
    File.basename(self.content_file_name,'.pdf').split('_')[5].to_i.to_s rescue nil
  end

  class << self
    def by_position
      asc(:position)
    end

    def update_file pack, combined_file, cover, is_an_upload=false
      start_at_page = pack.pages.not_covers.size + 1
      temp_path = pack.original_document.content.path
      basename = File.basename(temp_path,".pdf")
      if cover.present?
        system "pdftk #{cover} burst output #{basename}_covers_%d.pdf"
        add_pages pack, basename, -2, false, true
      end
      if combined_file.present?
        system "pdftk #{combined_file} burst output #{basename}_pages_%03d.pdf_"
        rename_pages start_at_page
        add_pages pack, basename, start_at_page, is_an_upload
      end
      update_original_file temp_path, combined_file, cover
    end

    def rename_pages start_at_page
      Dir.glob("*_pages*").each_with_index do |file,index|
        number = start_at_page + index
        new_name = file.sub /[0-9]{3}\.pdf_/, ("%03d" % number) + ".pdf"
        File.rename file, new_name
      end
    end

    def add_pages(pack, basename, start_at_page, is_an_upload, is_a_cover=false)
      pattern = is_a_cover ? "*_covers*" : "*_pages*"
      Dir.glob("#{basename}" + pattern).sort.each_with_index do |file, index|
        document = Document.new
        document.dirty = true
        document.pack = pack
        document.position = start_at_page + index
        document.content = File.new file
        document.is_an_upload = is_an_upload
        document.is_a_cover = is_a_cover
        document.save
        File.delete file
      end
    end

    def update_original_file temp_path, combined_file, cover
      File.rename temp_path, temp_path + "_"
      input = ''
      order = ''
      if cover.present?
        input << "A=#{cover}"
        order << "A"
      end
      input << " B=#{temp_path}_"
      order << " B"
      if combined_file.present?
        input << " C=#{combined_file}"
        order << " C"
      end

      system "pdftk #{input} cat #{order} output #{temp_path}"
      system "rm #{temp_path}_ #{combined_file}"
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
      tess = Tesseract::Process.new(path, lang: :fra, convert_options: { input: ["-density 200 -colorspace Gray -depth 8 -alpha off"] } )
      words = tess.to_s.split(/\n/).join(' ').split(' ').uniq.select { |e| e.size > 1 }
      self.content_text = ''
      words.each do |word|
        if Dictionary.find_one(word)
          self.content_text += ' ' + word
        end
      end
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

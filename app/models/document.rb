# -*- encoding : UTF-8 -*-
class Document
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Paperclip

  field :content_file_name
  field :content_file_type
  field :content_file_size, :type => Integer
  field :content_updated_at, :type => Time
  field :content_text, :type => String, :default => ""
  field :is_an_original, :type => Boolean, :default => false
  field :is_an_upload, :type => Boolean, :default => false
  field :tags, :type => String, :default => ""
  field :position, :type => Integer
  field :dirty, :type => Boolean, :default => true
  field :indexed, :type => Boolean, :default => false

  references_many :document_tags, :dependent => :destroy
  referenced_in :pack

  has_mongoid_attached_file :content,
    :styles => {
      :thumb => ["46x67>", :png],
      :medium => ["92x133", :png]
    }
  
  before_content_post_process do |image|
    if image.dirty || image.dirty.nil? # halts processing
      false
    else
      true
    end
  end
  
  after_post_process :split_pages
  after_create :add_tags

  scope :without_original, :where => { :is_an_original.in => [false, nil] }
  scope :originals, :where => { :is_an_original => true }
  
  scope :not_extracted, :where => { :content_text => "" }
  scope :extracted, :not_in => { :content_text => [""] }
  scope :cannot_extract, :where => { :content_text => "-[none]" }
  
  scope :not_indexed, :not_in => { :indexed => [true] }
  scope :indexed, :where => { :indexed => true }
  
  scope :not_clean, :where => { :dirty => true }
  scope :clean, :where => { :dirty => false }
  
  scope :uploaded, :where => { :is_an_upload => true }
  scope :scanned, :where => { :is_an_upload => false }
  
public
  def verified_content_text
    self.content_text.split(" ").select { |word| word.match(/\+/) }.map { |word| word.sub(/^\+/,"") }
  end
  
  def by_position
    asc(:position)
  end
  
protected
  def split_pages
    if self.is_an_original
      temp_file = content.to_file
      temp_path = File.expand_path(temp_file.path)
      nbr = File.basename(self.content_file_name, ".pdf")
      system "pdftk #{temp_path} burst output /tmp/#{nbr}_pages_%03d.pdf"

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
  
  class << self
    def find_ids_by_tags tags, user, ids=[]
      document_ids = ids
      tags.each_with_index do |tag,index|
        if index == 0 && document_ids.empty?
          document_ids = DocumentTag.where(:user_id => user.id, :name => / #{tag}/).distinct(:document_id)
        else
          document_ids = DocumentTag.any_in(:document_id => document_ids).where(:user_id => user.id, :name => / #{tag}/).distinct(:document_id)
        end
      end
      document_ids
    end
  
    def update_file pack, filename, is_an_upload=false
      start_at_page = pack.documents.size
      tempfile = pack.original_document.content.to_file
      temp_path = File.expand_path(tempfile.path)
      basename = File.basename(temp_path,".pdf")
      
      basename = File.basename pack.original_document.content_file_name, ".pdf"
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
  
    def do_reprocess_styles
      puts "Beginning reprocess."
      total = self.not_clean.without_original.count
      while total > 0
        documents = self.not_clean.without_original.limit(50)
        documents.each do |document|
          document.content.reprocess!
          document.dirty = false
          if document.save
            print "."
          else
            print "!"
          end
        end
        total -= 50
      end
      puts "\nEnd of reprocess."
    end
    
    def extract_content
      documents = Document.without_original.not_extracted.entries
      puts "Nombre de document à indexé : #{documents.count}"
      
      checkpoint_timer = Time.now
      documents.each_with_index do |document,index|
        if ((Time.now - checkpoint_timer) > 10.seconds)
          puts "Zzz"
          sleep(2)
          checkpoint_timer = Time.now
        end
        print "[#{index + 1}]"
        receiver = Receiver.new
        result = PDF::Reader.file("#{Rails.root}/public#{document.content.url.sub(/\.pdf.*/,'.pdf')}",receiver) rescue false
        if result
          print "ok\n"
          document.content_text = receiver.text
          if document.content_text == ""
            document.content_text = "-[none]"
          end
          document.save!
        else
          print "not ok\n"
        end
      end
    end
  end
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
          @text += " +#{word}"
        else
          @text += " #{word}"
        end
      end
    end
  end
  def show_text_with_positioning(array, *params)
    show_text array.select { |element| element.is_a? String }.join()
  end
end

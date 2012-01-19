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
  field :tags, :type => String, :default => ""
  field :position, :type => Integer
  field :dirty, :type => Boolean, :default => true
  field :indexed, :type => Boolean, :default => false

  references_many :document_tags
  referenced_in :pack
  has_and_belongs_to_many  :words

  has_mongoid_attached_file :content,
    :styles => {
      :thumb => ["46x67>", :png],
      :medium => ["92x133", :png],
      :large => ["480x696", :png]
    }
  
  before_content_post_process do |image|
    if image.dirty || image.dirty.nil? # halts processing
      false
    else
      true
    end
  end
  
  after_post_process :split_pages

  scope :without_original, :where => { :is_an_original.in => [false, nil] }
  scope :originals, :where => { :is_an_original => true }
  scope :not_indexed, :not_in => { :indexed => [true] }
  
  def self.do_reprocess_styles
    nb = 0
    self.where(:dirty => true).each do |doc|
      nb += 1
      puts "document[#{doc.content_file_name}][#{nb}]"
      doc.dirty = false
      doc.content.reprocess!
      if !doc.save
        doc.dirty = true
      end
    end
    puts "Document reprocessed number : #{nb}"
  end
  
  def self.extract_content
    documents = Document.without_original.not_indexed.entries
    puts "Nombre de document à indexé : #{documents.count}"
    
    documents.each_with_index do |document,index|
      print "[#{index + 1}]"
      receiver = Receiver.new
      result = PDF::Reader.file("#{Rails.root}/public#{document.content.url.sub(/\.pdf.*/,'.pdf')}",receiver) rescue false
      if result
        print "ok\n"
        document.content_text = receiver.text
        document.indexed = true
        document.save!
      else
        print "not ok\n"
      end
    end
  end

protected

  def split_pages
    if dirty
      Rails.logger.debug("entering split pages")
      if self.is_an_original
        temp_file = content.to_file
        temp_path = File.expand_path(temp_file.path)
        nbr = File.basename(self.content_file_name, ".pdf")
        cmd = "pdftk #{temp_path} burst output /tmp/#{nbr}_pages_%02d.pdf"
        Rails.logger.debug("Will split document with #{cmd}")
        system(cmd)

        Dir.glob("/tmp/#{nbr}_*").sort.each_with_index do |file, index|
          document = Document.new
          document.dirty = true
          document.pack = self.pack
          document.position = index
          document.content = File.new file
          document.save
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
    string.split().each do |w|
      word = w.scan(/[\w|.|@|_|-]+/).join().downcase
      if word.length <= 50
        if Dictionary.find_one(word)
          @text += " +#{word}"
        else
          @text += " #{word}"
        end
      end
    end
  end
  def show_text_with_positioning(array, *params)
    show_text(array.select{|i| i.is_a?(String)}.join())
  end
end
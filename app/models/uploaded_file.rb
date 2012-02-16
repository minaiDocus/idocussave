class UploadedFile
  include Mongoid::Document
  include Mongoid::Timestamps
  
  VALID_EXTENSION = [".pdf",".bmp",".jpeg",".jpg",".png",".tiff",".tif",".gif"]
  
  after_create :do_process
  
  referenced_in :user
  
  field :basename, :type => String
  field :account_book_type, :type => String
  field :number, :type => String
  field :original_filename, :type => String
  field :is_ocr_needded, :type => Boolean, :default => true
  field :is_delivered, :type => Boolean, :default => false
  
  validates_presence_of :original_filename, :account_book_type
  
  scope :valid, :where => { :is_valid => true }
  scope :not_valid, :where => { :is_valid => false }
  scope :delivered, :where => { :delivered => true }
  scope :not_delivered, :where => { :delivered => false }
  
  validate :validity_of_extension
  
public
  def processing_filename
    "#{self.basename}_#{self.number}#{self.original_extension}"
  end
  
  def pack_name
    "#{self.basename}_all"
  end
  
  def moov_file tempfile
    Dir.chdir("#{Rails.root}/tmp/input_pdf_auto/ocr_tasks/")
    new_name = "#{self.basename}_#{self.number}#{self.original_extension}"
    file = File.new(new_name,'w+')
    FileUtils.copy_stream(tempfile,file)
    file.rewind
  end
  
  def is_password_protected?
    if self.original_extension == ".pdf"
      # FIXME use more predicted code
      !system("pdftk #{Rails.root}/tmp/input_pdf_auto/ocr_tasks/#{processing_filename} dump_data output /dev/null")
    else
      false
    end
  end
  
  def delete_file
    system("rm #{Rails.root}/tmp/input_pdf_auto/ocr_tasks/#{processing_filename}")
  end
  
  def do_process
    set_basename
    set_number
    self.save
  end

  def set_basename
    unless account_book_type.blank?
      month = Time.now.month > 9 ? Time.now.month.to_s : "0"+Time.now.month.to_s
      year = Time.now.year.to_s
      self.basename = "#{self.user.code}_#{self.account_book_type}_#{year}#{month}"
    end
  end
  
  def set_number
    nb = 0
    if filename = get_last_similar_filename(".")
      nb = filename.split('_')[3].sub('.pdf','').to_i + 1
      if nb == 0
        if filename = get_last_similar_filename("..")
          nb = filename.split('_')[3].sub('.pdf','').to_i + 1
          nb = 500 if nb < 500 && nb > 999
        else
          nb = 500
        end
      else
        nb = 500 if nb < 500 && nb > 999
      end
    else
    end
    self.number = (1000+nb).to_s[1..3]
  end
  
  def original_extension
    File.extname(self.original_filename) rescue ""
  end
  
  def get_last_similar_filename path
    Dir.entries("#{Rails.root}/tmp/input_pdf_auto/ocr_tasks/#{path}").select{|d| d.match(/^#{self.basename}/)}.sort.last
  end
  
  def validity_of_extension
    unless VALID_EXTENSION.include?(original_extension.downcase)
      errors.add(:original_extension, "Extension '#{original_extension}' is not valid, valid is : #{VALID_EXTENSION.join(' ')}")
    else
      true
    end
  end

end
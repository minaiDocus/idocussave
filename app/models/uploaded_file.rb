# -*- encoding : UTF-8 -*-
class UploadedFile
  include Mongoid::Document
  include Mongoid::Timestamps
  
  VALID_EXTENSION = %w(.pdf .bmp .jpeg .jpg .png .tiff .tif .gif)
  UPLOADED_FILE_PATH = File.join([Pack::FETCHING_PATH,'uploads'])
  
  referenced_in :user
  
  field :basename,          type: String
  field :account_book_type, type: String
  field :page_number,       type: Integer
  field :original_filename, type: String
  field :is_ocr_needded,    type: Boolean, default: true
  field :is_delivered,      type: Boolean, default: false
  
  validates_presence_of :original_filename, :basename, :account_book_type, :page_number
  
  scope :delivered,     where: { delivered: true }
  scope :not_delivered, where: { delivered: false }
  
public

  def pack_name
    self.basename + "_all"
  end
  
  class << self
    def init
      Dir.mkdir UPLOADED_FILE_PATH
    end
    
    def make(user, sAccountBookType, sOriginalFilename, tempfile, for_current_period)
      raise UploadError::UnprocessableEntity.new('Corrupted file') unless system("identify #{tempfile.path}")

      Dir.chdir UPLOADED_FILE_PATH
      #  Validate extension.
      sExtension = File.extname(sOriginalFilename).downcase
      raise UploadError::InvalidFormat.new("Extension [#{sExtension}] is not valid") unless VALID_EXTENSION.include? sExtension

      is_quarterly = user.scan_subscriptions.last.period_duration == 3

      #  Get basename.
      sBasename = ""
      is_current = true
      if for_current_period == "false"
        if is_quarterly
          sMonth = "T#{quarterly_of_month(3.months.ago.month)}"
          sYear = 3.month.ago.year.to_s
        else
          sMonth = "%0.2d" % 1.month.ago.month
          sYear = 1.month.ago.year.to_s
        end
        sBasename = user.code + "_" + sAccountBookType + "_" + sYear + sMonth
        
        pack = user.packs.where(name: sBasename.gsub("_"," ") + " all").first
        if pack
          if pack.is_open_for_upload
            is_current = false
          end
        else
          is_current = false
        end
      end
      
      if is_current
        if is_quarterly
          sMonth = "T#{quarterly_of_month(Time.now.month)}"
        else
          sMonth = "%0.2d" % Time.now.month
        end
        sYear = Time.now.year.to_s
        sBasename = user.code + "_" + sAccountBookType + "_" + sYear + sMonth
      end
      
      #  Get number.
      iNumber = get_number sBasename
      
      #  Mooving tempfile.
      sNewFilename = sBasename + "_" + iNumber + sExtension
      file = File.new(sNewFilename,'w+')
      FileUtils.copy_stream(tempfile,file)
      file.rewind
      file.close
      
      #  Verify if pdf file is password protected.
      is_protected = is_password_protected? sNewFilename, sExtension
      
      if !is_protected
        if sExtension != ".pdf"
          name = sNewFilename.sub(/#{sExtension}/,".pdf")
          system "convert #{sNewFilename} #{name}"
          File.delete sNewFilename
          sNewFilename = name
        end
        
        #  Get page number.
        iPageNumber = get_page_number sNewFilename
        
        system "cp #{sNewFilename} ../"
        pack = Pack.find_or_create_by_name sBasename.gsub("_"," ") + " all", user
        
        Dir.chdir Pack::FETCHING_PATH
        Pack.add [sNewFilename], pack, true
        
        Dir.chdir UPLOADED_FILE_PATH
        File.rename sNewFilename, "up_" + sNewFilename
        
        user.uploaded_files.create(original_filename: sOriginalFilename, basename: sBasename, page_number: iPageNumber, account_book_type: sAccountBookType, is_delivered: true)
      else
        File.delete sNewFilename
        raise UploadError::ProtectedFile.new('The file is password protected')
      end
    end
    
    def get_page_number(sFilename)
      `pdftk #{sFilename} dump_data`.scan(/NumberOfPages: [0-9]+/)[0].scan(/[0-9]+/)[0].to_i rescue 0
    end
    
    def get_number(sBasename)
      nb = 0
      filename = get_last_similar_filename(sBasename, ".")
      if filename
        nb = filename.split('_')[4].sub('.pdf','').to_i + 1
      else
        filename = get_last_similar_filename(sBasename, "..")
        if filename
          nb = filename.split('_')[4].sub('.pdf','').to_i + 1
        end
      end
      nb = 500 if nb < 500 || nb > 999
      (1000+nb).to_s[1..3]
    end
    
    def get_last_similar_filename(sBasename, path)
      Dir.entries("#{path}").select{|d| d.match(/^up_#{sBasename}/)}.sort.last
    end
    
    def is_password_protected?(sFilename, sExtension)
      if sExtension == ".pdf"
        !system("pdftk #{sFilename} dump_data output /dev/null")
      else
        false
      end
    end

    def quarterly_of_month(month)
      if month < 4
        1
      elsif month < 7
        2
      elsif month < 10
        3
      else
        4
      end
    end
  end
end

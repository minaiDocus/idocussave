class UploadedFile
  include Mongoid::Document
  include Mongoid::Timestamps
  
  VALID_EXTENSION = [".pdf",".bmp",".jpeg",".jpg",".png",".tiff",".tif",".gif"]
  UPLOADED_FILE_PATH = "#{Rails.root}/tmp/input_pdf_auto/uploads/"
  
  referenced_in :user
  
  field :basename, :type => String
  field :account_book_type, :type => String
  field :page_number, :type => Integer
  field :original_filename, :type => String
  field :is_ocr_needded, :type => Boolean, :default => true
  field :is_delivered, :type => Boolean, :default => false
  
  validates_presence_of :original_filename, :basename, :account_book_type, :page_number
  
  scope :delivered, :where => { :delivered => true }
  scope :not_delivered, :where => { :delivered => false }
  
public
  def pack_name
    self.basename + "_all"
  end
  
  class << self
    def init
      Dir.mkdir UPLOADED_FILE_PATH
    end
    
    def make user, sAccountBookType, sOriginalFilename, tempfile, for_current_month
      Dir.chdir UPLOADED_FILE_PATH
      #  Validate extension.
      sExtension = File.extname(sOriginalFilename).downcase
      raise TypeError, 'Extension is not valid' unless VALID_EXTENSION.include? sExtension
      
      #  Get basename.
      sBasename = ""
      is_current = true
      if for_current_month == "false"
        sMonth = (Time.now.month - 1) > 9 ? (Time.now.month - 1).to_s : "0" + (Time.now.month - 1).to_s
        sYear = (Time.now - 1.month).year.to_s
        sBasename = user.code + "_" + sAccountBookType + "_" + sYear + sMonth
        
        pack = user.packs.where(:name => sBasename.gsub("_"," ") + " all").first
        if pack
          if pack.is_open_for_uploaded_file
            is_current = false
          end
        else
          is_current = false
        end
      end
      
      if is_current
        sMonth = Time.now.month > 9 ? Time.now.month.to_s : "0"+Time.now.month.to_s
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
        if pack.information["uploaded"]
          pack.information["uploaded"]["pages"] += iPageNumber
          pack.information["uploaded"]["sheets"] += 1
          pack.information["uploaded"]["pieces"] += 1
        else
          pack.information["uploaded"] = {}
          pack.information["uploaded"]["pages"] = iPageNumber
          pack.information["uploaded"]["sheets"] = 1
          pack.information["uploaded"]["pieces"] = 1
        end
        Dir.chdir Pack::FETCHING_PATH
        Pack.add [sNewFilename], pack
        
        Dir.chdir UPLOADED_FILE_PATH
        File.rename sNewFilename, "up_" + sNewFilename
        
        user.uploaded_files.create(:original_filename => sOriginalFilename, :basename => sBasename, :page_number => iPageNumber, :account_book_type => sAccountBookType, :is_delivered => true)
      else
        File.delete sNewFilename
        raise ArgumentError, 'The file is password protected'
      end
    end
    
    def get_page_number sFilename
      `pdftk #{sFilename} dump_data`.scan(/NumberOfPages: [0-9]+/)[0].scan(/[0-9]+/)[0].to_i rescue 0
    end
    
    def get_number sBasename
      nb = 0
      filename = get_last_similar_filename(sBasename, ".")
      if filename
        nb = filename.split('_')[3].sub('.pdf','').to_i + 1
      else
        filename = get_last_similar_filename(sBasename, "..")
        if filename
          nb = filename.split('_')[3].sub('.pdf','').to_i + 1
        end
      end
      nb = 500 if nb < 500 || nb > 999
      (1000+nb).to_s[1..3]
    end
    
    def get_last_similar_filename sBasename, path
      Dir.entries("#{path}").select{|d| d.match(/^#{sBasename}/)}.sort.last
    end
    
    def is_password_protected? sFilename, sExtension
      if sExtension == ".pdf"
        !system("pdftk #{sFilename} dump_data output /dev/null")
      else
        false
      end
    end
  end
end
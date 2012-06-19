class Pack
  include Mongoid::Document
  include Mongoid::Timestamps
  
  FETCHING_PATH = "#{Rails.root}/tmp/input_pdf_auto/"
  STAMP_PATH = "#{Rails.root}/tmp/stamp.pdf"

  referenced_in :owner, :class_name => "User", :inverse_of => :own_packs
  references_and_referenced_in_many :users
  
  referenced_in :order
  references_many :documents, :dependent => :destroy
  references_many :document_tags
  references_many :scan_documents, :class_name => "Scan::Document", :inverse_of => :pack
  embeds_many :divisions
  
  field :name, :type => String
  field :is_open_for_upload, :type => Boolean, :default => true
  field :is_delivered_to_external_file_storage, :type => Boolean, :default => false
  
  after_save :update_reporting_document
  
  scope :scan_delivered, :where => { :is_open_for_uploaded_file => false }
  scope :delivered_to_efs, :where => { :is_delivered_to_external_file_storage => true }
  scope :not_delivered_to_efs, :where => { :is_delivered_to_external_file_storage => false }
  
  def pages
    self.documents.without_original
  end
  
  def sheets
    self.divisions.sheets
  end
  
  def pieces
    self.divisions.pieces
  end
  
  def find_scan_document start_time, end_time
    self.scan_documents.for_time(start_time,end_time).first
  end
  
  def find_or_create_scan_document start_time, end_time, period
    sd = find_scan_document(start_time, end_time)
    if sd
      sd
    else
      sd = Scan::Document.new
      sd.name = name
      sd.period = period
      sd.pack = self
      sd.save
      sd
    end
  end
  
  def update_reporting_document
    total = divisions.count
    period_duration = 0
    time = created_at
    while total > 0
      period = owner.find_or_create_scan_subscription.find_or_create_period(time)
      current_divisions = divisions.select{ |division| division.created_at > period.start_at and division.created_at < period.end_at }
      if !current_divisions.empty?
        document = find_or_create_scan_document(period.start_at,period.end_at,period)
        if document
          document.sheets = current_divisions.select{ |division| division.level == Division::PIECES_LEVEL }.count
          document.pieces = current_divisions.select{ |division| division.level == Division::SHEETS_LEVEL }.count
          document.pages = self.pages.where(:created_at.gt => period.start_at, :created_at.lt => period.end_at).count
          
          document.uploaded_pieces = current_divisions.select{ |division| division.is_an_upload == true}.select{ |division| division.level == Division::PIECES_LEVEL }.count
          document.uploaded_sheets = current_divisions.select{ |division| division.is_an_upload == true}.select{ |division| division.level == Division::SHEETS_LEVEL }.count
          document.uploaded_pages = self.pages.uploaded.where(:created_at.gt => period.start_at, :created_at.lt => period.end_at).count
          
          document.is_shared = self.order.is_viewable_by_prescriber
          document.save
        end
        if document.pages - document.uploaded_pages > 0
          period.delivery.update_attributes(:state => "delivered")
        end
        time += period.duration.month
        total -= current_divisions.count
      end
    end
  end
  
  def get_document name, in_dir_manual=true
    document = Document.new
    document.is_an_original = true
    document.dirty = true
    document.pack = self
    if in_dir_manual
      document.content = File.new "#{Rails.root}/tmp/input_pdf_manual/#{name}.pdf"
    else
      document.content = File.new "#{Rails.root}/tmp/input_pdf_auto/#{name.split('_')[0..2].join('_')}_all/#{name}.pdf"
    end
    if document.save!
      self.order.scanned! unless self.order.scanned?
      system("rm -r #{Rails.root}/tmp/input_pdf_manual/#{name}.pdf") if in_dir_manual
    end
  end
  
  def original_document
    documents.originals.first
  end
  
  def historic
    _documents = self.documents.asc(:created_at).without_original.entries
    current_date = _documents.first.created_at
    @events = [{:date => current_date, :uploaded => 0, :scanned => 0}]
    current_offset = 0
    _documents.each do |document|
      if document.created_at > current_date.end_of_day
        current_date = document.created_at
        current_offset += 1
        @events << {:date => current_date, :uploaded => 0, :scanned => 0}
      end
      if document.is_an_upload
        @events[current_offset][:uploaded] += 1
      else
        @events[current_offset][:scanned] += 1
      end
    end
    @events
  end
  
  class << self
    def own
      where(:user => self.order.user)
    end
    
    def observed
      excludes(:user => self.order.user)
    end
    
    def shared_by
      self.order.user
    end
    
    def find_by_name name
      where(:name => name).first
    end
    
    def find_ids_by_tags tags, user, ids=[]
      pack_ids = ids
      tags.each_with_index do |tag,index|
        if index == 0 && pack_ids.empty?
          pack_ids = DocumentTag.where(:user_id => user.id, :name => / #{tag}/).distinct(:pack_id)
        else
          pack_ids = DocumentTag.any_in(:pack_id => pack_ids).where(:user_id => user.id, :name => / #{tag}/).distinct(:pack_id)
        end
      end
      pack_ids
    end
    
    def find_or_create_by_name name, user
      if pack = find_by_name(name)
        pack
      else
        order = user.subscription.order rescue user.orders.last
        order = Order.create!(:user_id => user.id, :state => "scanned", :manual => true) unless order
        pack = Pack.new
        pack.name = name
        pack.order = order
        pack
      end
    end
    
    def valid_documents
      Dir.entries("./").select{|f| f.match(/\w+_\w+_\w+_\d+\.(pdf|PDF)$/)}
    end
    
    def downcase_extension
      valid_documents.each do |file_name,index|
        if file_name.match(/\.PDF$/)
          File.rename(file_name, file_name.sub(/\.PDF$/,'.pdf'))
        end
      end
    end
    
    def page_number_of document
      `pdftk #{document} dump_data`.scan(/NumberOfPages: [0-9]+/).join().scan(/[0-9]+/).join().to_i rescue 0
    end
    
    def get_file_from_numen target_dir="diadeis2depose/LIVRAISON"
      Dir.chdir "#{Rails.root}/tmp/input_pdf_auto"
      Dir.mkdir("NUMEN_DELIVERY_BACKUP") unless File.exist?("NUMEN_DELIVERY_BACKUP")
      Dir.chdir("NUMEN_DELIVERY_BACKUP")
      
      require "net/ftp"
      
      ftp = Net::FTP.new('193.168.63.12', 'depose', 'tran5fert')
      
      ftp.chdir(target_dir)
      rootFilesName = ftp.nlst.sort
      headers = rootFilesName.select { |e| e.match(/\.txt$/) }
      
      processed_headers = Dir.glob("*.txt")
      headers = headers - processed_headers
      
      headers.each do |header|
        folderName = rootFilesName.select { |e| e.match(/#{File.basename(header,".txt")}$/) }.first
        puts "Looking at folder : #{folderName}"
        ftp.chdir(folderName)
        foldersName = ftp.nlst.sort
        
        allFilesName = []
        
        Dir.mkdir(folderName) unless File.exist?(folderName)
        Dir.chdir(folderName)
        foldersName.each do |folderName|
          ftp.chdir(folderName)
          filesName = ftp.nlst.sort
          allFilesName += filesName
          filesName.each do |fileName|
            if fileName.match(/\w+_\w+_\w+_\d{3}\.(pdf|PDF)$/)
              unless File.exist?(fileName)
                print "\tTrying to fetch document named #{fileName}..."
                ftp.getbinaryfile(fileName)
                print "done\n"
              else
                puts "\tHad already fetched document named #{fileName}"
              end
              # ftp.delete(fileName)
            end
          end
          ftp.chdir("../")
        end
        
        is_ok = true
        allFilesName.each do |filename|
          if `pdftk #{filename} dump_data`.empty?
            is_ok = false
          end
        end
        
        if is_ok
          allFilesName.each { |fileName| system("cp #{fileName} ../../") }
        else
          ErrorNotitication::EMAILS.each do |email|
            delay(:queue => 'error notification', :priority => 100).NotificationMailer.notify(email,"Récupération des documents","Bonjour,<br /><br />L'un au moins des fichiers livrés par Numen est corrompu." )
          end
        end
        
        Dir.chdir("..")
        ftp.chdir("..")
        File.new(header,"w")
      end
      
      ftp.close
    end
    
    def get_documents
      Dir.chdir "#{Rails.root}/tmp/input_pdf_auto"
      downcase_extension
      filesname = valid_documents.sort
      # traiter un document à la fois
      while !filesname.empty?
        filename = filesname.first
        basename = filename.sub(/_[0-9]{3}\.pdf/,"")
        user_code = filename.split("_")[0]
        pack_filesname = filesname.find_all { |f| f.match(/#{basename}/) }
        if user = User.where(:code => user_code).first
          pack = find_or_create_by_name basename.gsub("_"," ") + " all", user
          add pack_filesname, pack
        end
        Dir.chdir "#{Rails.root}/tmp/input_pdf_auto"
        
        filesname -= pack_filesname
      end
    end
    
    def add filesname, pack, is_an_upload=false
      user = pack.order.user
      pack_name = pack.name.gsub(" ","_")
      pack_filename = pack_name + ".pdf"
      
      init_and_moov_to pack_name, filesname
      pack.is_open_for_upload = false if is_an_upload == false
      
      #  Renommage des fichiers.
      start_at_page = pack.divisions.pieces.count + 1
      filesname = apply_new_name filesname, start_at_page
      update_division(filesname, pack, is_an_upload)
      #  Création du fichier all.
      filesname_list = filesname.sum { |f| " " + f }
      system "pdftk #{filesname_list} cat output #{pack_filename}"
      
      #  Vérification de l'existance ou pas.
      if pack.persisted?
        #  Mise à jour des documents.
        Document.update_file pack, pack_filename, is_an_upload
        pack.save
      else
        #  Attribution du pack.
        pack.owner = user
        pack["user_ids"] = pack["user_ids"] + user.find_or_create_reporting.viewer.map { |e| e.id }
        
        document = Document.new
        document.dirty = true
        document.is_an_original = true
        document.is_an_upload = is_an_upload
        document.pack = pack
        document.content = File.new pack_filename
        
        pack.save ? document.save : false
        if pack.order.state == "paid"
          pack.order.scanned!
        end
      end
      
      delay(:queue => 'external file storage delivery').deliver_to_external_file_storage(pack.id, [user.id,user.prescriber.try(:id)], [Dir.pwd, filesname + [pack_filename]], info_path(pack_name,user))
    end
    
    def info_path pack_name, user=nil
      name_info = pack_name.split("_")
      info = {}
      info[:code] = name_info[0]
      info[:company] = user.try(:company)
      info[:account_book] = name_info[1]
      info[:year] = name_info[2][0..3]
      info[:month] = name_info[2][4..5]
      info[:delivery_date] = Time.now.strftime("%Y%m%d")
      info
    end
    
    def default_delivery_path pack_name
      part = pack_name.split "_"
      "/#{part[0]}/#{part[2]}/#{part[1]}/"
    end
    
    def deliver_to_external_file_storage pack_id, user_ids, filespath, infopath
      pack = Pack.find(pack_id)
      users = User.find(user_ids)
      Dir.chdir(filespath[0])
      filesname = filespath[1]
      users.each do |user|
        if user
          if user.external_file_storage
            user.external_file_storage.deliver filesname, infopath
          end
          if user.is_prescriber and user.is_dropbox_extended_authorized and !user.dropbox_delivery_folder.nil?
            DropboxExtended.deliver filesname, user.dropbox_delivery_folder, infopath
          end
        end
      end
      #  Marquage des fichiers comme étant traité.
      filesname.each do |filename|
        unless filename.match(/all\.pdf$/)
          File.rename filename, "up_" + filename
        end
      end
      pack.update_attributes(:is_delivered_to_external_file_storage => true)
    end
    
  private
    def update_division filesname, pack, is_an_upload
      total_pages = 0
      count = pack.documents.count
      current_page = (count == 0) ? 1 : count
      current_position = pack.sheets.last.position + 1 rescue 1
      
      filesname.each do |filename|
        name = filename.sub(".pdf","")
        pages_number = page_number_of filename
        
        sheet = Division.new
        sheet.level = Division::SHEETS_LEVEL
        piece = Division.new
        piece.level = Division::PIECES_LEVEL
        
        piece.created_at = piece.updated_at = sheet.created_at = sheet.updated_at = Time.now
        
        piece.name = sheet.name = name
        piece.start = sheet.start = current_page
        current_page += pages_number
        piece.end = sheet.end = current_page - 1
        piece.is_an_upload = sheet.is_an_upload = is_an_upload
        piece.position = sheet.position = current_position
        pack.divisions << piece
        pack.divisions << sheet
        
        current_position += 1
        total_pages += pages_number
      end
    end
  
    def init_and_moov_to name, filesname
      Dir.mkdir name rescue nil
      filesname.each { |filename| system "mv #{filename} #{name}" }
      Dir.chdir name
      File.delete name + ".pdf" rescue nil
    end
  
    def apply_new_name filesname, starting_page
      filesname.each { |filename| File.rename filename, filename + "_"  }
      start = starting_page
      filesname.map do |filename|
        new_filename = generate_new_name(filename,(start += 1) - 1)
        stamp_path = generate_stamp(new_filename.gsub("_"," ").sub(".pdf",""))
        system "pdftk #{filename}_ stamp #{stamp_path} output #{new_filename}"
        system "rm #{filename}_"
        new_filename
      end
    end
    
    def generate_new_name filename, number
      zero_filler = "0" * (3 - number.to_s.size)
      filename.sub /[0-9]{3}\.pdf/, zero_filler + number.to_s + ".pdf"
    end
    
    def generate_stamp text
      Prawn::Document.generate STAMP_PATH, :margin => 0 do
        fill_color "FF0000"
        rotate(330, :origin => [495,780]) do
          draw_text text, :size => 10, :at => [495, 780]
        end
      end
      STAMP_PATH
    end
  end
end
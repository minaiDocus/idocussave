# -*- encoding : UTF-8 -*-
class Pack
  include Mongoid::Document
  include Mongoid::Timestamps

  ALL           = 0
  ORIGINAL_ONLY = 1
  PIECES_ONLY   = 2
  REPORT        = 3
  
  FETCHING_PATH = "#{Rails.root}/files/tmp"
  STAMP_PATH = "#{Rails.root}/tmp/stamp.pdf"

  referenced_in :owner, class_name: "User", inverse_of: :own_packs
  references_and_referenced_in_many :users

  references_many :documents,                                                         dependent: :destroy
  references_many :pieces,          class_name: "Pack::Piece",     inverse_of: :pack, dependent: :destroy, autosave: true
  references_one  :report,          class_name: "Pack::Report",    inverse_of: :pack
  references_many :document_tags,                                                     dependent: :destroy
  references_many :scan_documents,  class_name: "Scan::Document",  inverse_of: :pack
  references_many :remote_files,                                                      dependent: :destroy
  embeds_many :divisions
  
  field :name,                     type: String
  field :is_open_for_upload, type: Boolean, default: true
  
  after_save :update_reporting_document

  scope :scan_delivered, where: { is_open_for_upload: false }

  def pages
    self.documents.without_original
  end

  def original_document
    documents.originals.first
  end
  
  def sheets_info
    self.divisions.sheets
  end
  
  def pieces_info
    self.divisions.pieces
  end
  
  def find_scan_document(start_time, end_time)
    self.scan_documents.for_time(start_time,end_time).first
  end
  
  def find_or_create_scan_document(start_time, end_time, period)
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
    total = divisions.size
    time = created_at
    while total > 0
      period = owner.find_or_create_scan_subscription.find_or_create_period(time)
      current_divisions = divisions.of_month(time)
      if current_divisions.any?
        document = find_or_create_scan_document(period.start_at,period.end_at,period)
        if document
          document.sheets = current_divisions.sheets.count
          document.pieces = current_divisions.pieces.count
          document.pages = self.pages.of_month(time).count
          document.uploaded_pieces = current_divisions.uploaded.pieces.count
          document.uploaded_sheets = current_divisions.uploaded.sheets.count
          document.uploaded_pages = self.pages.uploaded.of_month(time).count
          document.save
        end
        if document.pages - document.uploaded_pages > 0
          period.delivery.update_attributes(:state => "delivered")
        end
      end
      total -= current_divisions.count
      time += period.duration.month
    end
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

  def init_delivery_for(user, type=Pack::ALL, force=false)
    current_remote_files = []
    efs = user.find_or_create_efs
    efs.active_services_name.each do |service_name|
      # original
      if type.in? [Pack::ALL, Pack::ORIGINAL_ONLY]
        temp_remote_files = original_document.get_remote_files(user,service_name)
        temp_remote_files.each { |remote_file| remote_file.waiting! }
        current_remote_files += temp_remote_files
      end
      # pieces
      if type.in? [Pack::ALL, Pack::PIECES_ONLY]
        self.pieces.each do |piece|
          temp_remote_files = piece.get_remote_files(user,service_name)
          temp_remote_files.each { |remote_file| remote_file.waiting! } if force
          current_remote_files += temp_remote_files
        end
      end
      # report
      if type.in?([Pack::ALL, Pack::REPORT]) && report
        temp_remote_files = report.get_remote_files(user,service_name)
        temp_remote_files.each { |remote_file| remote_file.waiting! } if force
        current_remote_files += temp_remote_files
      end
    end
    current_remote_files
  end

  class << self
    def find_by_name(name)
      where(name: name).first
    end

    def find_or_create_by_name(name, user)
      find_by_name(name) || Pack.new(owner_id: user.id, name: name)
    end

    def search_ids_by_contents(contents)
      documents = Document.any_in(pack_id: self.all.distinct(:_id))
      documents.search_by_contents(contents).distinct(:pack_id)
    end

    def search_by_contents(contents)
      any_in(_id: search_ids_by_contents(contents))
    end

    def search_ids_by_tags(tags)
      queries = tags.split(' ').map { |e| /#{e}/i }
      pack_ids = self.all.distinct(:_id)
      DocumentTag.any_in(pack_id: pack_ids).
                  all_in(name: queries).
                  distinct(:pack_id)
    end

    def search_by_tags(tags)
      any_in(_id: search_ids_by_tags(tags))
    end

    def search_for(contents)
      pack_ids = []
      contents.split(' ').each_with_index do |content,index|
        temp_pack_ids = search_ids_by_contents(content) + search_ids_by_tags(content)
        if index != 0
          pack_ids = temp_pack_ids.select { |e| e.in? pack_ids }
        else
          pack_ids = temp_pack_ids
        end
      end
      any_in(_id: pack_ids)
    end

    def find_words_by_tag(tag)
      contents = DocumentTag.any_in(pack_id: self.all.distinct(:_id)).where(name: /\w*#{tag}\w*/).distinct(:name)
      words = contents.map { |e| e.scan(/\w*#{tag}\w*/) }.flatten
      words.uniq.map { |e| { id: '1', name: e } }
    end

    def find_words_by_content(content)
      documents = Document.any_in(pack_id: self.all.distinct(:_id))
      contents = documents.search_by_contents(content).distinct(:content_text)
      words = contents.map { |e| e.scan(/\w*#{content}\w*/) }.flatten
      words.uniq.map { |e| { id: '0', name: e } }
    end

    def find_words(word)
      (find_words_by_content(word) + find_words_by_tag(word)).uniq.sort { |a,b| a[:name] <=> b[:name] }
    end
    
    def valid_documents
      Dir.entries("./").select{|f| f.match(/\w+_\w+_\w+_\d+\.(pdf|PDF)$/)}
    end
    
    def downcase_extension
      valid_documents.each do |file_name|
        if file_name.match(/\.PDF$/)
          File.rename(file_name, file_name.sub(/\.PDF$/,'.pdf'))
        end
      end
    end
    
    def page_number_of(document)
      `pdftk #{document} dump_data`.scan(/NumberOfPages: [0-9]+/).join().scan(/[0-9]+/).join().to_i rescue 0
    end

    def get_file_from_numen(target_dir="diadeis2depose/LIVRAISON")
      Dir.chdir FETCHING_PATH
      Dir.mkdir("NUMEN_DELIVERY_BACKUP") unless File.exist?("NUMEN_DELIVERY_BACKUP")
      Dir.chdir("NUMEN_DELIVERY_BACKUP")

      require "net/ftp"

      ftp = Net::FTP.new('193.168.63.12', 'depose', 'tran5fert')

      ftp.chdir(target_dir)
      root_files_name = ftp.nlst.sort
      headers = root_files_name.select { |e| e.match(/\.txt$/) }

      processed_headers = Dir.glob("*.txt")
      headers = headers - processed_headers

      total_filesname = []

      headers.each do |header|
        folder_name = root_files_name.select { |e| e.match(/#{File.basename(header,".txt")}$/) }.first
        puts "Looking at folder : #{folder_name}"
        ftp.chdir(folder_name)
        folders_name = ftp.nlst.sort

        all_filesname = []

        Dir.mkdir(folder_name) unless File.exist?(folder_name)
        Dir.chdir(folder_name)
        folders_name.each do |foldername|
          ftp.chdir(foldername)
          files_name = ftp.nlst.sort
          all_filesname += files_name
          files_name.each do |file_name|
            if file_name.match(/\w+_\w+_\w+_\d{3}\.(pdf|PDF)$/)
              unless File.exist?(file_name)
                print "\tTrying to fetch document named #{file_name}..."
                ftp.getbinaryfile(file_name)
                print "done\n"
              else
                puts "\tHad already fetched document named #{file_name}"
              end
              # ftp.delete(fileName)
            end
          end
          ftp.chdir("../")
        end

        is_ok = true
        filesname_with_error = []
        all_filesname.each do |filename|
          if `pdftk #{filename} dump_data`.empty?
            is_ok = false
            filesname_with_error << filename
          end
        end

        if is_ok
          path = File.join([RegroupSheet::FILES_PATH,Time.now.strftime('%Y%m%d')])
          cached_path = RegroupSheet::CACHED_FILES_PATH
          FileUtils.mkdir_p(cached_path)
          all_filesname.each do |filename|
            info = filename.split('_')
            code = info[0]
            journal = info[1]
            user = User.where(code: code).first
            account_book_type = nil
            account_book_type = user.account_book_types.where(name: journal).first if user
            if account_book_type && account_book_type.compta_processable?
              FileUtils.mkdir_p(path)
              FileUtils.cp(filename,File.join([path, filename]))
              FileUtils.cp(filename,File.join([cached_path, filename]))
            else
              FileUtils.cp(filename,File.join([Pack::FETCHING_PATH,filename]))
              total_filesname << filename
            end
          end
        else
          ErrorNotification::EMAILS.each do |email|
            NotificationMailer.notify(email,"Récupération des documents","Bonjour,<br /><br />Les fichiers suivant livrés par Numen sont corrompus :<br />#{filesname_with_error.join(', ')}." ).deliver
          end
        end

        Dir.chdir("..")
        ftp.chdir("..")
        File.new(header,"w")
      end

      ftp.close

      total_filesname
    end
    
    def get_documents(files)
      Dir.chdir FETCHING_PATH
      if files.nil?
        filesname = []
      else
        if files.empty?
          downcase_extension
          filesname = valid_documents.sort
        else
          filesname = files
        end
      end
      data = []
      # traiter un document à la fois
      while !filesname.empty?
        filename = filesname.first
        basename = filename.sub(/_[0-9]{3}\.pdf/,"")
        user_code = filename.split("_")[0]
        pack_filesname = filesname.find_all { |f| f.match(/#{basename}/) }
        if user = User.where(:code => user_code).first
          pack = find_or_create_by_name basename.gsub("_"," ") + " all", user
          data << add(pack_filesname, pack)
        end
        Dir.chdir FETCHING_PATH
        
        filesname -= pack_filesname
      end
      data
    end

    def deliver_mail(data)
      while data.any?
        email = data.first[0]
        tempdata = data.select { |d| d[0] == email }
        filesname = tempdata.map { |e| e[1] }
        PackMailer.new_document_available(User.find_by_email(email), filesname).deliver
        data = data - tempdata
      end
    end
    
    def add(filesname, pack, is_an_upload=false)
      user = pack.owner
      pack_name = pack.name.gsub(" ","_")
      pack_filename = pack_name + ".pdf"
      
      init_and_moov_to pack_name, filesname
      pack.is_open_for_upload = false if is_an_upload == false
      
      #  Renommage des fichiers.
      start_at_page = pack.divisions.pieces.count + 1
      filesname = apply_new_name(filesname, start_at_page, user.stamp_name, user.is_stamp_background_filled, is_an_upload)

      piece_position = pack.pieces_info.last.position + 1 rescue 1
      sheet_position = pack.sheets_info.last.position + 1 rescue 1
      update_pieces(filesname, pack, piece_position, is_an_upload)
      update_division(filesname, pack, piece_position, sheet_position, is_an_upload)

      #  Création du fichier all.
      filesname_list = filesname.sum { |f| " " + f }
      system "pdftk #{filesname_list} cat output #{pack_filename}"
      
      #  Vérification de l'existance ou pas.
      if pack.persisted?
        #  Mise à jour des documents.
        Document.update_file pack, pack_filename, is_an_upload
        pack.updated_at = Time.now
        pack.save
      else
        #  Attribution du pack.
        pack.owner = user
        pack.users << user
        pack.users << user.prescriber
        pack.users = pack.users + user.share_with

        document = Document.new
        document.dirty = true
        document.is_an_original = true
        document.is_an_upload = is_an_upload
        document.pack = pack
        document.content = File.new pack_filename

        document.save
        pack.save
      end

      #  Marquage des fichiers comme étant traité.
      filesname.each do |filename|
        File.rename filename, "up_" + filename
      end

      pack.init_delivery_for(user)
      pack.init_delivery_for(user.prescriber) if user.prescriber

      [user.email,pack_filename,piece_position]
    end
    
    def info_path(pack_name, user=nil)
      name_info = pack_name.split("_")
      pack = Pack.find_by_name(name_info.join(' '))
      info = {}
      info[:code] = name_info[0]
      info[:company] = user.try(:company)
      info[:company_of_customer] = pack.owner.company
      info[:account_book] = name_info[1]
      info[:year] = name_info[2][0..3]
      info[:month] = name_info[2][4..5]
      info[:delivery_date] = Time.now.strftime("%Y%m%d")
      info
    end
    
    def default_delivery_path(pack_name)
      part = pack_name.split "_"
      "/#{part[0]}/#{part[2]}/#{part[1]}/"
    end

  private

    def update_division(filesname, pack, piece_position, sheet_position, is_an_upload)
      total_pages = 0
      count = pack.documents.count
      current_page = (count == 0) ? 1 : count
      current_piece_position = piece_position
      current_sheet_position = sheet_position

      filesname.each do |filename|
        name = filename.sub(".pdf","")
        pages_number = page_number_of filename

        piece = Division.new
        piece.level = Division::PIECES_LEVEL
        
        piece.created_at = piece.updated_at = Time.now
        
        piece.name = name
        piece.start = current_page
        piece.end = current_page + pages_number - 1
        piece.is_an_upload = is_an_upload
        piece.position = current_piece_position
        pack.divisions << piece

        if is_an_upload
          sheet = Division.new
          sheet.level = Division::SHEETS_LEVEL
          sheet.created_at = sheet.updated_at = Time.now
          sheet.name = name.sub(/\d{3}$/,'%0.3d' % current_sheet_position)
          sheet.start = current_page
          sheet.end = current_page + pages_number - 1
          sheet.is_an_upload = is_an_upload
          sheet.position = current_sheet_position
          pack.divisions << sheet
          current_sheet_position += 1
        else
          (pages_number / 2).times do |i|
            sheet = Division.new
            sheet.level = Division::SHEETS_LEVEL
            sheet.created_at = sheet.updated_at = Time.now
            sheet.name = name.sub(/\d{3}$/,'%0.3d' % current_sheet_position)
            sheet.start = current_page + (i*2)
            sheet.end = current_page + (i*2) + 1
            sheet.is_an_upload = is_an_upload
            sheet.position = current_sheet_position
            pack.divisions << sheet
            current_sheet_position += 1
          end
        end

        current_page += pages_number
        current_piece_position += 1
        total_pages += pages_number
      end
    end

    def update_pieces(filesname, pack, position, is_an_upload)
      current_position = position
      filesname.each do |filename|
        piece = Pack::Piece.new
        piece.pack = pack
        piece.name = File.basename(filename,'.pdf').gsub('_',' ')
        piece.content = open(filename)
        piece.is_an_upload = is_an_upload
        piece.position = current_position
        current_position += 1
      end
    end
  
    def init_and_moov_to(name, filesname)
      Dir.mkdir name rescue nil
      filesname.each { |filename| system "mv #{filename} #{name}" }
      Dir.chdir name
      File.delete name + ".pdf" rescue nil
    end
  
    def apply_new_name(filesname, starting_page, stamp_name, is_stamp_background_filled, is_an_upload)
      filesname.each { |filename| File.rename filename, filename + "_"  }
      start = starting_page
      filesname.map do |filename|
        new_filename = generate_new_name(filename,(start += 1) - 1)
        stamp_path = generate_stamp(new_filename.gsub("_"," ").sub(".pdf",""), stamp_name, is_stamp_background_filled, is_an_upload, filename)
        system "pdftk #{filename}_ stamp #{stamp_path} output #{new_filename}"
        system "rm #{filename}_"
        new_filename
      end
    end
    
    def generate_new_name(filename, number)
      zero_filler = "0" * (3 - number.to_s.size)
      filename.sub /[0-9]{3}\.pdf/, zero_filler + number.to_s + ".pdf"
    end
    
    def generate_stamp(text, stamp_name, is_stamp_background_filled, is_an_upload, filename)
      filepath = './' + filename + '_'
      size = Poppler::Document.new(filepath).pages[0].size
      txt = generate_stamp_name(text,stamp_name,is_an_upload)
        Prawn::Document.generate STAMP_PATH, page_size: size, top_margin: 10 do
          if is_stamp_background_filled
            bounding_box([0, bounds.height], :width => bounds.width) do
              data = [[txt]]
              table(data, position: :center) do
                style(row(0), border_color: "FF0000", text_color: "FFFFFF", background_color: "FF0000")
                style(columns(0), background_color: "FF0000", border_color: "FF0000", align: :center)
              end
            end 
          else
            fill_color "FF0000"
            text txt, size: 10, :align => :center
          end
        end
      STAMP_PATH
    end
  
    def generate_stamp_name(text, stamp_name, is_an_upload)
      txt = stamp_name
      info = text.split(' ')
      
      origin = is_an_upload ? "INF" : "PAP"
     
      txt.gsub(':code', info[0]).
      gsub(':account_book', info[1]).
      gsub(':period', info[2]).
      gsub(':piece_num', info[3]).
      gsub(':origin', origin)
    end
  end
end

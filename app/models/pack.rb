class Pack
  include Mongoid::Document
  include Mongoid::Timestamps

  references_and_referenced_in_many :users
  
  referenced_in :order
  references_many :documents, :dependent => :delete
  
  field :name, :type => String
  field :division, :type => Array, :default => []
  field :information, :type => Hash, :default => {"page_number" => 0, "collection" => [], "name" => ""}
  field :customs, :type => Integer, :default => 0
  
  after_save :update_reporting
  
  def update_reporting
    monthly = self.order.user.find_or_create_reporting.find_or_create_monthly_by_date(self.created_at) rescue nil
    if monthly
      document = monthly.find_or_create_document_by_name self.name
      if !self.information.nil? && !self.information.empty?
        document.sheets = document.pieces = self.information["collection"].count rescue 0
        document.pages = self.information["page_number"]
        document.customs = self.customs
      end
      document.is_shared = self.order.is_viewable_by_prescriber
      monthly.save
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
  
  def get_division_from_pdf
    url = "#{Rails.root}/public#{self.documents.where(:is_an_original => true).first.content.url.sub(/\.pdf.*/,'.pdf')}"
    metadata = `pdftk #{url} dump_data`

    number_of_page = metadata.scan(/NumberOfPages: \d+/).to_s.scan(/\d+/).to_s.to_i

    bookmarks = metadata.scan(/BookmarkTitle: \w+\nBookmarkLevel: \d+\nBookmarkPageNumber: \d+/)

    level_number = 1
    
    div = {}
    div[:pieces] = []
    
    unless bookmarks.empty?
      bookmarks.each_with_index do |bookmark,index|
        inter = []
        level_number = 1
        bookmark.split(/\n/).each_with_index do |b,ind|
          inter << b.split(/: /)[1]
          
          if ind == 1 && information.split(/: /)[1].to_i == 2
            level_number = 2
          end
        end
        
        div[:pieces] << { :name => inter[0], :level => inter[1].to_i, :start => inter[2].to_i }
        
        if index != 0
          div[:pieces][-1][:end] = inter[2].to_i - 1
        end
      end
    else
      div[:pieces] << { :name => self.name, :start => 1, :end => number_of_page, :level => 1 }
    end
    div[:level] = level_number
    div[:page_number] = number_of_page
    
    self.information = div
    self.save
  end
  
  def safe_get_division_from_pdf
    self.get_division_from_pdf if !self.information || self.information.empty?
  end
  
  def match_tags tags, user=order.user
    tags = Iconv.iconv('UTF-8', 'ISO-8859-1', tags).join().split(':_:')
    match_tag = true

    document_tag = DocumentTag.where(:document_id => self.documents.first.id, :user_id => user.id).first rescue nil
    unless document_tag
      match_tag = false
    else
      tags.each{ |tag| match_tag = false unless document_tag.name.match(/ #{tag}/) }
    end

    match_tag ? true : false
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
    
    def moov_to folder, document_names
      Dir.mkdir(folder)
      document_names.each do |document_name|
        system("mv #{document_name} #{folder}")
      end
      Dir.chdir(folder)
    end
    
    def get_documents
      # changement de répertoire
      Dir.chdir("#{Rails.root}/tmp/input_pdf_auto")

      # réecriture de l'extension en minuscule s'il ne l'est pas déjà
      downcase_extension

      files = []
      
      # réorganisation par pack des fichiers ayant les même préfix, triée par order alphabétique
      file_names = valid_documents.sort
      total_documents = file_names.count
      while (!file_names.empty?) do
        prefix_name = file_names[0].split('_')[0..2].join('_')
        user_code = prefix_name.split('_')[0]
        doc_names = file_names.select{|f| f.match(/#{prefix_name}_[0-9]+\.pdf/)}.sort
        
        collection = []
        doc_names.each{ |doc_name| collection << {:name => doc_name} }
        
        files << { :collection => collection, :user_code => user_code, :prefix_name => prefix_name }
        file_names -= doc_names
      end
      
      # ajout du nombre de page pour chaque document
      files.each_with_index do |file,index|
        total_pages = 0
        file[:collection].each_with_index do |document,i|
          page_number = page_number_of document[:name]
          total_pages += page_number
          files[index][:collection][i][:page_number] = page_number
        end
        files[index][:page_number] = total_pages
      end
      
      puts "\n\n\n###############################################################################################\n\n"
      puts "#Date \t\t: #{Time.now}"
      puts "#Packs \t\t: #{files.count}"
      puts "#Documents \t: #{total_documents}\n\n"
      
      # traitement de chaque pack
      files.each_with_index do |file,index|
        pack_name = file[:prefix_name] + "_all"
        
        print "#{index} - #{pack_name}"
        
        # deplacement des fichiers dans un dossier temporaire
        moov_to pack_name, file[:collection].map{|d| d[:name]}
        
        user = User.where(:code => file[:user_code]).first
        if user
          print " - #{user.email}"
        
          pack_already_exists = true
          pack = user.packs.any_in(:name => [pack_name,pack_name.gsub('_',' ')]).first
        
          unless pack
            pack_already_exists = false
            order = user.subscription.order rescue user.orders.last
            unless order
              order = Order.create!(:user_id => user.id, :state => "paid", :manual => true)
            end
            pack = Pack.create!({:name => pack_name.gsub('_',' '), :order_id => order.id, :information => {"page_number" => 0, "collection" => [], "name" => ""},:customs => 0})
          end
          
          counter = 0
          if pack_already_exists
            print " - existant"
            counter = pack.information["page_number"]
          else
            print " - nouveau"
            pack.information["page_number"] = 0
          end
          
          print " - [#{pack.id}]\n"
          
          require "prawn" 
          
          collection_number = file[:collection].length
          collection_number.times do |i|
            
            zero_filler = "0" * (3 - (counter + i + 1).to_s.length)
            
            new_name = file[:collection][i][:name].sub(/_[0-9]+.pdf/,"_#{zero_filler + (counter + i + 1).to_s}.pdf")
            File.rename(file[:collection][i][:name], new_name+"__")
            file[:collection][i][:name] = new_name
            
            Prawn::Document.generate "stamp.pdf", :margin => 0 do
              fill_color "FF0000"
              stroke_color "FF0000"
              rotate(330, :origin => [495,780]) do
                stroke_rectangle [493, 790], 124, 16
                draw_text new_name.sub(/\.pdf/,''), :size => 10, :at => [495, 780]
              end
            end
            
            system("pdftk #{file[:collection][i][:name]}__ stamp stamp.pdf output #{file[:collection][i][:name]}_")
          end
          system("rm *.pdf__ stamp.pdf")
          collection_number.times do |i|
            File.rename(file[:collection][i][:name]+"_",file[:collection][i][:name])
          end
          
          old_number_of_page = pack.information["page_number"]
          
          # mise à jour du nombre total de page
          pack.information["page_number"] += file[:page_number]
          
          last_page = 0
          if pack_already_exists
            last_page = pack.information["collection"][-1]["end"] rescue 0
          end
          
          pack.information["collection"] = [] if pack.information["collection"].nil?
          
          puts "\t\tpage\t\tfeuille"
          puts "ancien\t\t#{old_number_of_page}\t\t#{pack.information["collection"].count}"
          puts "nouveau\t\t#{file[:page_number]}\t\t#{file[:collection].count}"
          
          # mis à jour de la division
          file[:collection].each do |document|
            pack.information["collection"] << { :name => document[:name].sub(/\.pdf$/,''), :level => "1", :start => (last_page + 1), :end => (last_page + document[:page_number]) }
            last_page += document[:page_number]
          end
          
          puts "total\t\t#{pack.information['page_number']}\t\t#{pack.information['collection'].count}"
          
          document_list = file[:collection].map{ |document| " #{document[:name]}" }
          
          # assemblage des pdf
          cmd = "pdftk#{document_list} cat output #{pack_name}.pdf"
          system(cmd)
          
          if pack_already_exists
            prefix = pack.documents.where(:is_an_original => true).first.content_file_name.scan(/\w+/)[0]
            
            # division en page
            cmd = "pdftk #{pack_name}.pdf burst output #{prefix}_pages_%03d.pdf_"
            system(cmd)
            
            number_of_page = file[:page_number] 
            
            number_of_page.times do |i|
              new_number = old_number_of_page + i + 1
            
              zero_filler = "0" * (3 - (i + 1).to_s.length)
              old_name = "#{prefix}_pages_#{zero_filler + (i + 1).to_s}.pdf_"
              zero_filler = "0" * (3 - new_number.to_s.length)
              new_name = "#{prefix}_pages_#{zero_filler + new_number.to_s}.pdf"
              File.rename(old_name,new_name)
              
              # création d'un document pour chaque page
              document = Document.new
              document.dirty = true
              document.pack = pack
              document.position = new_number
              document.content = File.new new_name
              document.save
              
              document_tag = DocumentTag.new
              document_tag.document = document.id
              document_tag.user = user.id
              document_tag.generate
              document_tag.save!
            end
            
            system("rm #{prefix}_pages_*")
          
            # mis à jour du document original
            original_document = pack.documents.where(:is_an_original => true).first
            temp_file = original_document.content.to_file
            temp_path = File.expand_path(temp_file.path)
            basename = File.basename(temp_path)
            
            ### correction sur le nom des fichiers ###
            cmd = "cp '#{temp_path}' ./#{pack_name}.pdf_"
            system(cmd)
            
            ### correction sur le nom des fichiers ###
            cmd = "pdftk A='#{basename}_' B=#{pack_name}.pdf cat A B output '#{temp_path}'"
            system(cmd)
            
            system("rm #{basename}_ doc_data.txt")
            
          else
            pack.get_document pack_name, false
            pack.documents.each do |document|
              document_tag = DocumentTag.new
              document_tag.document = document.id
              document_tag.user = user.id
              document_tag.generate
              document_tag.save!
            end
          end
          
          part = pack_name.split('_')
          path = "/#{part[0]}/#{part[2]}/#{part[1]}/"
          
          # chargement dans la dropbox du propriétaire
          if user.is_dropbox_authorized
            dropbox = user.my_dropbox
            if dropbox
              session = dropbox.new_session
              if session.authorized?
                puts "\nLivraison dans la dropbox du client #{user.email} [#{user.id}]"
                client = DropboxClient.new(session, Dropbox::ACCESS_TYPE)
                file[:collection].map{|f| f[:name]}.each_with_index do |document,i|
                  if i != 0
                    f = open(document)
                    client.put_file("#{path}#{document}",f) rescue nil
                  end
                end
                f = open("#{pack_name}.pdf")
                client.file_delete("#{path}#{pack_name}.pdf") rescue nil
                client.put_file("#{path}#{pack_name}.pdf",f) rescue nil
              end
            end
          end
          
          # chargement dans la dropbox du prescripteur
          prescriber = user.prescriber
          if prescriber
            if prescriber.is_dropbox_authorized
              dropbox = prescriber.my_dropbox
              if dropbox
                session = dropbox.new_session
                if session.authorized?
                  puts "\nLivraison dans la dropbox du prescripteur #{prescriber.email} [#{prescriber.id}]"
                  client = DropboxClient.new(session, Dropbox::ACCESS_TYPE)
                  file[:collection].map{|f| f[:name]}.each_with_index do |document,i|
                    if i != 0
                      f = open(document)
                      client.put_file("#{path}#{document}",f) rescue nil
                    end
                  end
                  f = open("#{pack_name}.pdf")
                  client.file_delete("#{path}#{pack_name}.pdf") rescue nil
                  client.put_file("#{path}#{pack_name}.pdf",f) rescue nil
                end
              end
            end
          end
          
          # suppression du dossier temporaire et retour au dossier principale
          Dir.chdir("..")
          # system("rm -r #{pack_name}")
          
          if !pack_already_exists
            pack.users << user
            pack.users = pack.users + user.find_or_create_reporting.viewer
          end
          
          pack.save
        else
          print " - aucun\n"
        end
        puts "\n\n"
      end
      puts "###############################################################################################\n\n\n"
    end
  end
end
class Pack
  include Mongoid::Document
  include Mongoid::Timestamps

  references_and_referenced_in_many :users
  
  referenced_in :order
  references_many :documents, :dependent => :delete
  
  field :name, :type => String
  field :division, :type => Array
  
  def get_document name, in_dir_manual=true
    document = Document.new
    document.is_an_original = true
    document.dirty = true
    document.pack = self
    if in_dir_manual
      type = "manual"
    else
      type = "auto"
    end
    document.content = File.new "#{Rails.root}/tmp/input_pdf_#{type}/#{name}.pdf"
    if document.save!
      self.order.scanned! unless self.order.scanned?
      system("rm #{Rails.root}/tmp/input_pdf_#{type}/#{name}.pdf")
    end
  end
  
  def get_division_from_pdf
    url = "#{Rails.root}/public#{self.documents.where(:is_an_original => true).first.content.url.sub(/\.pdf.*/,'.pdf')}"
    metadata = `pdftk #{url} dump_data` # vérifier s'il n'y a pas eu d'erreur

    number_of_page = metadata.scan(/NumberOfPages: \d+/).to_s.scan(/\d+/).to_s.to_i

    bookmarks = metadata.scan(/BookmarkTitle: \w+\nBookmarkLevel: \d+\nBookmarkPageNumber: \d+/)

    level_number = 1
    div = []
    unless bookmarks.empty?
      bookmarks.each_with_index do |b,index|
        inter = []
        b.split(/\n/).each_with_index do |info,ind|
          inter << info.split(/: /)[1]
          if ind == 1 && info.split(/: /)[1].to_i == 2
            level_number = 2
          end
        end
        if index == 0
          div << inter
        else
          div[index - 1] << (inter[2].to_i - 1).to_s
          div << inter
        end
      end
      div[div.length - 1] << number_of_page.to_s
    else
      div << [self.name,1,1,number_of_page]
    end

    div = [level_number,number_of_page,div]
    self.division = div
    self.save
  end
  
  def match_tags tags, user=order.user
    tags = Iconv.iconv('UTF-8', 'ISO-8859-1', tags).join().split(':_:')
    match_tag = true

    document_tag = DocumentTag.where(:document_id => self.documents.first.id, :user_id => user.id).first
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
    
    def get_documents
      # changement de répertoire
      Dir.chdir("#{Rails.root}/tmp/input_pdf_auto")

      # récupérer les fichiers pdf dans le répertoire
      document_names = Dir.entries("./").select{|f| f.match(/\w+_\w+_\w+_\d+\.(pdf|PDF)$/)}

      # réecriture de l'extension en minuscule s'il ne l'est pas déjà
      document_names.each_with_index do |document_name,index|
        if document_name.match(/\.PDF$/)
          new_name = document_name.sub(/\.PDF$/,'.pdf')
          File.rename(document_name, new_name)
          document_names[index] = new_name
        end
      end

      # réorganisation par pack des fichiers ayant les même préfix, triée par order alphabétique
      document_packs = []
      while (!document_names.empty?) do
        prefix_name = document_names[0].split('_')[0..2].join('_')
        document_packs << document_names.join('\\').scan(/#{prefix_name}_[0-9]+\.pdf/).sort
        document_names -= document_packs[-1].to_a
      end

      # ajout du nombre de page pour chaque document
      document_packs.each_with_index do |document_pack,index|
        total_pages = 0
        document_pack.each_with_index do |document,i|
          number_of_page = `pdftk #{document} dump_data`.scan(/NumberOfPages: [0-9]+/).join().scan(/[0-9]+/).join().to_i
          document_pack[i] = [document,number_of_page]
          total_pages += number_of_page
        end
        document_packs[index] = [total_pages] + document_packs[index]
      end

      # traitement de chaque pack
      document_packs.each do |document_pack|
        user_code = document_pack[1][0].split('_')[0]
        original_doc_name = document_pack[1][0].split('_')[0..2].join('_') + "_all"
        
        # deplacement des fichiers dans un dossier temporaire
        Dir.mkdir(original_doc_name)
        document_pack.each_with_index do |document,index|
          if index != 0
            cmd = "mv #{document[0]} #{original_doc_name}"
            system(cmd)
          end
        end
        Dir.chdir(original_doc_name)
        
        user = User.where(:code => user_code).first
        if user
          pack_already_exists = true
          pack = user.packs.where(:name => original_doc_name).first
          unless pack
            pack = user.packs.where(:name => original_doc_name.gsub('_',' ')).first
          end
        
          unless pack
            pack_already_exists = false
            order = user.subscription.order rescue user.orders.last
            unless order
              order = Order.create!(:user_id => user.id, :state => "paid", :manual => true)
            end
            pack = Pack.create!(:name => original_doc_name.gsub('_',' '), :order_id => order.id)
            order.save
          end

          counter = 0
          if pack_already_exists
            pack.get_division_from_pdf if !pack.division || pack.division.empty?
            counter = pack.division[-1][-1][0].split('_')[3].to_i
          else
            pack.division = [1,0,[]]
          end
          
          document_pack.each_with_index do |document,index|
            if index != 0
              counter += 1 
              zero_filler = "0" * (3 - counter.to_s.length)
              
              new_name = document[0].sub(/_[0-9]+.pdf/,"_#{zero_filler + counter.to_s}.pdf")
              File.rename(document[0], new_name)
              document_pack[index] = [new_name,document[1]]
            end
          end
          old_number_of_page = pack.division[1]
          
          # mis à jour du nombre total de page
          pack.division[1] += document_pack[0]
          
          if pack_already_exists
            last_page = pack.division[-1][-1][3].to_i
          else
            last_page = 0
          end
          
          # mis à jour de la division
          document_pack.each_with_index do |document,index|
            if index != 0
              pack.division[-1] << [document[0].sub(/\.pdf$/,''),"1",(last_page + 1).to_s,(last_page + document[1]).to_s]
              last_page += document[1]
            end
          end
          
          document_list = ""
          document_pack.each_with_index do |document,index|
            document_list += " #{document[0]}" if index != 0
          end
          
          # assemblage des pdf
          cmd = "pdftk#{document_list} cat output #{original_doc_name}.pdf"
          puts cmd
          system(cmd)
          
          if pack_already_exists
            prefix = pack.documents.where(:is_an_original => true).first.content_file_name.scan(/\w+/)[0]
            
            # division en page
            cmd = "pdftk #{original_doc_name}.pdf burst output #{prefix}_pages_%02d.pdf"
            puts cmd
            system(cmd)
            
            nbr = old_number_of_page
            
            number_of_page = document_pack[0]
            
            1..number_of_page.times do |i|
              nbr += 1
              zero_filler = "0" * (2 - (i + 1).to_s.length)
              old_name = "#{prefix}_pages_#{zero_filler + (i + 1).to_s}.pdf"
              zero_filler = "0" * (2 - nbr.to_s.length)
              new_name = "#{prefix}_pages_#{zero_filler + nbr.to_s}.pdf"
              File.rename(old_name,new_name)
              
              # création d'un document pour chaque page
              document = Document.new
              document.dirty = true
              document.pack = pack
              document.position = old_number_of_page + i + 1
              document.content = File.new new_name
              document.save
              
              document_tag = DocumentTag.new
              document_tag.document = document.id
              document_tag.user = user.id
              document_tag.generate
              document_tag.save!
            end
          
            # mis à jour du document original
            original_document = pack.documents.where(:is_an_original => true).first
            temp_file = original_document.content.to_file
            temp_path = File.expand_path(temp_file.path)
            basename = File.basename(temp_path)
            
            cmd = "cp '#{temp_path}' ./" 
            puts cmd
            system(cmd)
            
            cmd = "pdftk A='#{basename}' B=#{original_doc_name}.pdf cat A B output '#{temp_path}'"
            puts cmd
            system(cmd)
            
          else
            pack.get_document original_doc_name, false
            pack.documents.each do |document|
              document_tag = DocumentTag.new
              document_tag.document = document.id
              document_tag.user = user.id
              document_tag.generate
              document_tag.save!
            end
          end
          
          # chargement dans la dropbox du propriétaire
          if user.is_dropbox_authorized
            dropbox = user.my_dropbox
            if dropbox
              session = dropbox.new_session
              if session.authorized?
                client = DropboxClient.new(session, Dropbox::ACCESS_TYPE)
                document_pack.each_with_index do |document,i|
                  if i != 0
                    f = open(document[0])
                    client.put_file("/#{document[0]}",f) rescue nil
                  end
                end
              end
            end
          end
          
          # suppression du dossier temporaire et retour au dossier principale
          Dir.chdir("..")
          cmd = "rm -r #{original_doc_name}"
          system(cmd)
          
          pack.users << user
          reporting = Reporting.where(:client_ids => user.id).first
          if reporting
            pack.users << reporting.user
          end
            
          pack.save
        end
      end
      # retour au répertoire racine
      Dir.chdir("#{Rails.root}")
    end
    
    def find_document filter, user
      docs = []
      filter.split.each_with_index do |word,index|
        if index == 0
          docs = Document.any_in(:pack_id => user["pack_ids"]).where(:content_text => /\w*#{word}\w*/).entries
        else
          inter = []
          docs.each do |document|
            inter << document if document.content_text.match(/\w*#{word}\w*/)
          end
          docs = inter
        end
      end
      docs
    end
    
    def find_content filter, user
      result = []
      res = Document.any_in(:pack_id => user["pack_ids"]).where(:content_text => /\w*#{filter}\w*/).entries
      if res
        res.each do |document|
          document.content_text.scan(/[+]*\w*#{filter}\w*/).each do |word|
            if word.match(/^[+]/)
              result << [true,word.scan(/\w+/).join()]
            else
              # result << [false,word]
            end
          end
        end
      end
      result = result.uniq
    end
    
    def find_by_content filter, user
      docs = []
      filter.split.each_with_index do |word,index|
        inter = []
        if index == 0
          docs = Document.any_in(:pack_id => user["pack_ids"]).where(:content_text => /\w*#{word}\w*/).entries
        else
          docs.each do |document|
            inter << document if document.content_text.match(/*\w*#{word}\w*/)
          end
          docs = inter
        end
      end
      packs = []
      if docs
        docs.each do |document|
          packs << document.pack if !packs.include?(document.pack)
        end
      end
      packs
    end
    
  end
  
end
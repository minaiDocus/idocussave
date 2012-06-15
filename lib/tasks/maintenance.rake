namespace :maintenance do
  namespace :address do
    desc "Deliver updated address list"
    task :deliver_updated_list => [:environment] do
      AddressDeliveryList::process
    end
  end
  
  namespace :monthly do
    desc "Init current monthly"
    task :init => [:environment] do
      User.prescribers.each do |prescriber|
        prescriber.clients.active.each do |client|
          client.find_or_create_reporting.find_or_create_current_monthly
        end
      end
    end
  end
  
  namespace :invoice do
    desc "Generate invoice"
    task :generate => [:environment] do
      User.prescribers.not_in(:code => InvoiceConfig::IGNORE_CODES).each do |prescriber|
        puts Time.now
        if prescriber.is_centraliser
          puts "Generating invoice for prescriber : #{prescriber.name} <#{prescriber.email}>"
          invoice = Invoice.new
          invoice.user = prescriber
          invoice.save
          invoice.create_pdf
        else
          puts "Prescriber #{prescriber.name} <#{prescriber.email}>"
          clients = prescriber.clients - [prescriber]
          clients.each do |client|
            puts "\tgenerating invoice for client : #{client.name} <#{client.email}>"
            invoice = Invoice.new
            invoice.user = client
            invoice.save
            invoice.create_pdf
          end
        end
        puts Time.now
      end
    end
  end
  
  namespace :order do
    desc "Init to 234 Order sequence"
    task :init => [:environment] do
      seq = DbaSequence.where(:name => :order).first
      if seq
        puts "DbaSequence :order exists with current value : #{seq.counter}"
      else
        DbaSequence.create(:name => :order, :counter => 234)
        puts "DbaSequence initialized"
        end
    end

  end

  namespace :migrate do
    desc "Copy price_in_cents_wo_vat to new_price"
    task :product_new_price => [:environment] do
      Product.all.each do |p|
        p.new_price = p.price_in_cents_wo_vat
        p.save
        puts "#{p.title} up to date !"
      end
    end

    desc "Copy new_price into price_in_cents_wo_vat"
    task :product_price_bigdec => [:environment] do
      Product.all.each do |p|
        p.price_in_cents_wo_vat = p.new_price
        p.save
        puts "#{p.title} up to date !"
      end
    end
  end

  namespace :paperclip do
    desc "reprocess all images"
    task :reprocess => [:environment] do
      puts "processing documents"
      Document.all.each do |instance|
        instance.content.reprocess!
        print "."
      end
      puts "done with documents"
      puts "processing Compositions"
      Composition.all.each do |instance|
        instance.content.reprocess!
        print "."
      end
      puts "done with Compositions"
    end
  end

  task :textilize_pages => :environment do
    Page.all.each{|page|
      page.body = textilize page.body
      page.save
    }
  end

  namespace :lang do
    desc "Feed dictionary"
    task :feed, [:path] => :environment do |t,args|
      filename = File.expand_path(File.dirname(__FILE__)) + args[:path]
      
      puts "fetching dictionary at #{filename}"
      
      if File.exist?(filename)
        File.open(filename, 'r') do |file|
          while line = file.gets
            Dictionary.add Iconv.iconv('UTF-8', 'ISO-8859-1', line.chomp).join()
            print '.'
          end  
        end
      end
    end
  end
  
  namespace :pdf do
    desc "Extract pdf content to DB"
    task :extract_content => :environment do
      puts "The extraction begin..."
      
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
      
      documents = Document.not_in(:indexed => [true]).where(:is_an_original => false).entries
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
      
      puts "The extraction is finished."
    end
    
    desc "Fetch new scanned documents in /tmp/input_pdf_auto"
    task :get_documents => :environment do
      Pack.get_documents
    end
  end
  
end

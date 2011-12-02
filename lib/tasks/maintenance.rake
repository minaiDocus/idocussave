namespace :maintenance do
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
    task :extract_content_for, [:email] => :environment do |t,args|
    
      users = []
      if args[:email] == "all"
        users = User.all.entries
      else
        users << User.find_by_emails(args[:email].split(/,/))
      end
      
      users.each do |user|
        # Creating class for reading
        class Receiver
          attr_reader :text
          
          def initialize
            @text = ""
          end
          
          def show_text(string, *params)
            word = string.scan(/\w+/).join().downcase
            if word.length <= 50
              if Dictionary.find_one(word)
                @text += "+#{word}"
              else
                @text += word
              end
            end
          end
          
          def show_text_with_positioning(array, *params)
          show_text(array.select{|i| i.is_a?(String)}.join())
          end
        end
        
        puts "The extraction begin..."
        
        user.orders.each do |order|
          puts "Order number : #{order.number}"
          order.packs.each do |pack|
            puts "\tPack name : #{pack.name}"
            pack.documents.where(:is_an_original => true).entries.each do |document|
              document.indexed = true
              document.save
            end
            documents = pack.documents.not_in(:indexed => [true]).entries
            puts "\t\tTotal number of documents to process : #{documents.length}"
            if documents.length > 0
              documents.each_with_index do |document,index|
                receiver = Receiver.new
                result = PDF::Reader.file("#{Rails.root}/public#{document.content.url.sub(/\.pdf.*/,'.pdf')}",receiver) rescue false
                if result
                  print "\n\t\t\t[DOC-#{index + 1}]..."
                  document.content_text = receiver.text.split().uniq
                  document.indexed = true
                  document.save!
                else
                  print "!"
                end
              end
            else
              puts "Pass."
            end
          end
        end
        puts "The extraction is finished."
      end
    end
  end
  
end

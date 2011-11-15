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
  
  namespace :document do
    desc "Feed user dictionary"
    task :extract_content => :environment do
      class Receiver
        attr_reader :text
        
        def initialize
          @text = ""
        end
        
        def show_text(string, *params)
          @text += string
        end
        
        def show_text_with_positioning(array, *params)
        show_text(array.select{|i| i.is_a?(String)}.join())
        end
      end
      
      Document.where(:is_an_original => true).entries.each do |document|
        document.indexed = true
        document.save!
      end

      Document.where(:indexed => false).each do |document|
        user = document.pack.order.user
        
        receiver = Receiver.new
        PDF::Reader.file("/public#{document.content.url.sub(/\.pdf.*/,'.pdf')}",receiver)

        for w in receiver.text.split()
          if v_word = Dictionary.find_one(w)
            unless wd = Word.where(:content => v_word, :document_content_id => user.document_content.id)
              wd = Word.create!(:content => v_word, :document_content_id => user.document_content.id)
            end
            wd.documents << document  << document.pack.documents.where(:is_an_original => true).first
            wd.save!
          end
        end
        document.indexed = true
        document.save!
      end
    end
  end
  
end

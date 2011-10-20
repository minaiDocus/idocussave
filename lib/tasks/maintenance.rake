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

end

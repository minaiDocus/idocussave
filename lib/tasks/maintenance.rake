# -*- encoding : UTF-8 -*-
namespace :maintenance do
  namespace :documents do
    desc "Fecth documents"
    task :fetch => [:environment] do
      Pack.get_file_from_numen
      Pack.get_documents
      ReminderEmail.deliver
      Document.do_reprocess_styles
      Document.extract_content
      Document::Index.process
    end
  end
  
  namespace :address do
    desc "Deliver updated address list"
    task :deliver_updated_list => [:environment] do
      AddressDeliveryList::process
    end
  end

  namespace :reporting do
    desc "Init current period"
    task :init => [:environment] do
      User.prescribers.each do |prescriber|
        prescriber.clients.active.each do |client|
          begin
            client.scan_subscriptions.last.find_or_create_period Time.now
          rescue
            puts "Can't generate period for user #{client.code}<#{client.email}>, probably lack of scan_subscription entry."
          end
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
end

# -*- encoding : UTF-8 -*-
namespace :maintenance do
  namespace :documents do
    desc "Fecth documents"
    task :fetch => [:environment] do
      Pack.get_file_from_numen
      Pack.get_documents(nil)
      ReminderEmail.deliver
    end
  end
  
  namespace :address do
    desc "Deliver updated address list"
    task :deliver_updated_list => [:environment] do
      AddressDeliveryList::process
    end
  end

  namespace :notification do
    desc "Send update request notification"
    task :update_request => [:environment] do
      users = User.where(:request_type.gt => 0).asc([:code, :request_type])
      nb = users.count
      puts "[#{Time.now.strftime("%Y/%m/%d %H:%M")}] #{nb} update request(s) found."
      if nb > 0
        subject = 'Validation requise'
        content = ""
        content << "Bonjour,<br/><br/>"
        content << "Des requêtes de modification sont en attente de validation, pour le(s) client(s) suivant :<br/>"
        users.each do |user|
          content << user.info + " - " + I18n.t('request.'+User::REQUEST_TYPE_NAME[user.request_type])
          content << "<br/>"
        end
        content << "<br/>Cordialement, l'équipe iDocus"
        EventNotification::EMAILS.each do |email|
          print "[#{Time.now.strftime("%Y/%m/%d %H:%M")}] Sending email to <#{email}>..."
          NotificationMailer.notify(email,subject,content).deliver
          print "done.\n"
        end
      end
    end
  end

  namespace :reporting do
    desc "Init current period"
    task :init => [:environment] do
      User.prescribers.each do |prescriber|
        prescriber.clients.active.each do |client|
          begin
            subscription = client.scan_subscriptions.current
            subscription.remove_not_reusable_options
            subscription.find_or_create_period Time.now
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
      User.prescribers.invoiceable.each do |prescriber|
        puts Time.now
        if prescriber.is_centralizer
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

  namespace :compta do
    desc "Fetch report data"
    task :fetch_report, [:path] => :environment do
      Pack::Report.fetch
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

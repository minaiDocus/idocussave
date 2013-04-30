# -*- encoding : UTF-8 -*-
namespace :maintenance do
  namespace :documents do
    desc 'Fecth documents'
    task :fetch => [:environment] do
      Pack.get_file_from_numen
      Pack.get_documents(nil)
      ReminderEmail.deliver
    end
  end
  
  namespace :address do
    desc 'Deliver updated address list'
    task :deliver_updated_list => [:environment] do
      AddressDeliveryList.process
    end
  end

  namespace :notification do
    desc 'Send update request notification'
    task :update_request => [:environment] do
      user_ids = Request.active.where(requestable_type: 'User').asc([:action, :relation_action]).distinct(:requestable_id)
      user_ids = user_ids + Scan::Subscription.update_requested.distinct(:user_id)
      users = User.any_in(_id: user_ids).active.asc(:code)

      journal_ids = Request.active.where(requestable_type: 'AccountBookType').asc([:action, :relation_action]).distinct(:requestable_id)
      journals = AccountBookType.any_in(_id: journal_ids).asc([:name, :organization_id])

      puts "[#{Time.now.strftime("%Y/%m/%d %H:%M")}] #{users.count + journals.count} update request(s) found."
      if users.count > 0 || journals.count > 0
        subject = 'Validation requise'
        content = ""
        content << "Bonjour,<br/><br/>"
        content << "Des requ&ecirc;tes de modification sont en attente de validation, pour le(s) client(s) suivant :<br/>"
        users.each do |user|
          url = File.join([SITE_INNER_URL, 'admin/users', user.id.to_s])
          tag = "<a href='#{url}'>#{user.info}</a>"
          content << tag + " - " + I18n.t("request.#{user.request_status}")
          content << "<br/>"
        end
        content << "<br/>" if users.count > 0 && journals.count > 0
        content << "Des requ&ecirc;tes de modification sont en attente de validation, pour le(s) journau(x) suivant :<br/>"
        journals.each do |journal|
          url = File.join([SITE_INNER_URL, 'admin/organizations', journal.organization.slug])
          tag = "<a href='#{url}'>#{journal.organization.name}</a>"
          content << tag + " - " + journal.info + " - " + I18n.t("request.#{journal.request.status}")
          content << "<br/>"
        end
        content << "<br/>Cordialement, l'&eacute;quipe iDocus"
        EventNotification::EMAILS.each do |email|
          print "[#{Time.now.strftime("%Y/%m/%d %H:%M")}] Sending email to <#{email}>..."
          NotificationMailer.notify(email,subject,content).deliver
          print "done.\n"
        end
      end
    end
  end

  namespace :reporting do
    desc 'Init current period'
    task :init => [:environment] do
      Organization.all.each do |organization|
        organization.scan_subscriptions.current.remove_not_reusable_options
        organization.customers.active.each do |customer|
          begin
            subscription = customer.scan_subscriptions.current
            subscription.remove_not_reusable_options
            subscription.find_or_create_period Time.now
          rescue
            puts "Can't generate period for user #{customer.info}, probably lack of scan_subscription entry."
          end
        end
      end
    end
  end
  
  namespace :invoice do
    desc 'Generate invoice'
    task :generate => [:environment] do
      puts '##########################################################################################'
      puts "Task beginning at #{Time.now}"
      Organization.not_test.asc(:created_at).each do |organization|
        puts "Generating invoice for organization : #{organization.name}"
        if organization.customers.active.centralized.count > 0
          invoice = Invoice.new
          invoice.organization = organization
          invoice.user = organization.leader
          invoice.save
          print "-> Centralized invoice : #{invoice.number}..."
          invoice.create_pdf
          print "done\n"
          organization.customers.active.centralized.asc(:code).each do |customer|
            puts "\t#{customer.info}"
          end
        end
        if organization.customers.active.not_centralized.count > 0
          puts "-> Not centralized invoices :"
          organization.customers.active.not_centralized.asc(:code).each do |customer|
            invoice = Invoice.new
            invoice.user = customer
            invoice.save
            print "\t#{invoice.number} : #{customer.info}..."
            invoice.create_pdf
            print "done\n"
          end
        end
      end
      puts "Task end at #{Time.now}"
      puts '##########################################################################################'
    end
  end

  namespace :compta do
    desc 'Fetch report data'
    task :fetch_report, [:path] => :environment do
      Pack::Report.fetch
    end
  end

  namespace :lang do
    desc 'Feed dictionary'
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

# -*- encoding : UTF-8 -*-
namespace :maintenance do
  namespace :notification do
    desc 'Notify updated documents'
    task :document_updated => [:environment] do
      DocumentNotifier.notify_updated
    end

    desc 'Notify pending documents'
    task :document_pending => [:environment] do
      DocumentNotifier.notify_pending
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
            if subscription.period_duration == 1 || Time.now.month == Time.now.beginning_of_quarter.month
              subscription.remove_not_reusable_options
            end
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
          invoice.period = organization.periods.desc(:end_at).first
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
            invoice.period = customer.periods.desc(:end_at).first
            invoice.save
            print "\t#{invoice.number} : #{customer.info}..."
            invoice.create_pdf
            print "done\n"
          end
        end
      end
      Invoice.archive
      puts "Task end at #{Time.now}"
      puts '##########################################################################################'
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

  namespace :prepacompta do
    desc 'Update accounting plan'
    task :update_accounting_plan => [:environment] do
      users = []
      Organization.not_test.each do |organization|
        organization.account_book_types.compta_processable.each do |journal|
          users += journal.clients
        end
      end
      users.uniq!
      AccountingPlan.update_files_for(users.map(&:code))
    end
  end
end

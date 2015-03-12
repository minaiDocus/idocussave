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

    desc 'Notify scans not delivered'
    task :scans_not_delivered => [:environment] do
      ScanService.notify_not_delivered
    end
  end

  namespace :reporting do
    desc 'Init current period'
    task :init => [:environment] do
      Organization.all.each do |organization|
        RemoveNotReusableOptionsService.new(organization.subscription).execute
        organization.customers.active.each do |customer|
          begin
            subscription = customer.subscription
            if subscription.period_duration == 1 || Time.now.month == Time.now.beginning_of_quarter.month
              RemoveNotReusableOptionsService.new(subscription).execute
            end
            subscription.find_or_create_period Time.now
          rescue
            puts "Can't generate period for user #{customer.info}, probably lack of subscription entry."
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
      time = Time.now - 1.month
      time = Time.local(time.year, time.month)
      Organization.not_test.asc(:created_at).each do |organization|
        puts "Generating invoice for organization : #{organization.name}"
        periods = Period.where(:user_id.in => organization.customers.centralized.map(&:id)).where(start_at: time)
        if periods.count > 0 && organization.addresses.select{ |a| a.is_for_billing }.count > 0
          invoice = Invoice.new
          invoice.organization = organization
          invoice.user = organization.leader
          invoice.period = organization.periods.desc(:end_at).first
          invoice.save
          print "-> Centralized invoice : #{invoice.number}..."
          invoice.create_pdf
          print "done\n"
          periods.map(&:user).sort do |a, b|
            a.code <=> b.code
          end.each do |customer|
            puts "\t#{customer.info}"
          end
          InvoiceMailer.delay(priority: 1).notify(invoice)
        end
        periods = Period.where(:user_id.in => organization.customers.not_centralized.map(&:id)).where(start_at: time)
        if periods.count > 0
          puts "-> Not centralized invoices :"
          periods.map do |period|
            [period.user, period]
          end.sort do |a, b|
            a.first.code <=> b.first.code
          end.each do |customer, period|
            if customer.addresses.select{ |a| a.is_for_shipping }.count > 0
              invoice = Invoice.new
              invoice.user = customer
              invoice.period = period
              invoice.save
              print "\t#{invoice.number} : #{customer.info}..."
              invoice.create_pdf
              print "done\n"
              InvoiceMailer.delay(priority: 1).notify(invoice)
            end
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
      organization_ids = Organization.not_test.map(&:id)
      user_ids = AccountBookType.where(:user_id.exists => true).compta_processable.distinct(:user_id)
      users = User.where(:organization_id.in => organization_ids, :_id.in => user_ids).active

      AccountingPlan.update_files_for(users.map(&:code).sort)
    end
  end
end

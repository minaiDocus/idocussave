# -*- encoding : UTF-8 -*-
require 'elasticsearch/rails/tasks/import'

namespace :maintenance do
  namespace :notification do
    desc 'Notify updated documents'
    task :document_updated => [:environment] do
      puts "[#{Time.now}] maintenance:notification:document_updated - START"
      start_at = (Time.now - 12.hours).beginning_of_day
      end_at = start_at.end_of_day
      DocumentNotifier.notify_updated(start_at, end_at)
      puts "[#{Time.now}] maintenance:notification:document_updated - END"
    end

    desc 'Notify pending documents'
    task :document_pending => [:environment] do
      puts "[#{Time.now}] maintenance:notification:document_pending - START"
      DocumentNotifier.notify_pending
      puts "[#{Time.now}] maintenance:notification:document_pending - END"
    end

    desc 'Notify scans not delivered'
    task :scans_not_delivered => [:environment] do
      puts "[#{Time.now}] maintenance:notification:scans_not_delivered - START"
      ScanService.notify_not_delivered
      puts "\n[#{Time.now}] maintenance:notification:scans_not_delivered - END"
    end
  end

  namespace :reporting do
    desc 'Init current period'
    task :init => [:environment] do
      puts "[#{Time.now}] maintenance:reporting:init - START"
      Organization.all.each do |organization|
        DowngradeSubscription.new(organization.subscription).execute
        organization.customers.active.each do |customer|
          begin
            subscription = customer.subscription
            if subscription.period_duration == 1 || (subscription.period_duration == 3 && Time.now.month == Time.now.beginning_of_quarter.month) || (subscription.period_duration == 12 && Time.now.month == 1)
              DowngradeSubscription.new(subscription).execute
            end
            subscription.current_period
            if subscription.period_duration != 1
              time = 1.month.ago
              period = subscription.find_period time
              PeriodBillingService.new(period).save(time.month) if period
            end
          rescue
            puts "Can't generate period for user #{customer.info}, probably lack of subscription entry."
          end
        end
      end
      puts "[#{Time.now}] maintenance:reporting:init - END"
    end
  end

  namespace :orders do
    desc 'Comfirm all pending orders'
    task :comfirm_all_pending => [:environment] do
      puts "[#{Time.now}] maintenance:orders:comfirm_all_pending - START"
      Order.pending.each do |order|
        ConfirmOrder.new(order).execute
        print '.'
      end
      puts "\n[#{Time.now}] maintenance:orders:comfirm_all_pending - END"
    end
  end

  namespace :invoice do
    desc 'Generate invoice'
    task :generate => [:environment] do
      puts "[#{Time.now}] maintenance:invoice:generate - START"
      time = Time.now - 1.month
      time = Time.local(time.year, time.month)
      puts 'Updating all periods'
      Period.where(:start_at.lte => time.dup, :end_at.gte => time.dup).each do |period|
        UpdatePeriodDataService.new(period).execute
        UpdatePeriodPriceService.new(period).execute
        print '.'
      end
      puts ''
      Organization.billed.asc(:created_at).each do |organization|
        puts "Generating invoice for organization : #{organization.name}"
        periods = Period.where(:user_id.in => organization.customers.centralized.map(&:id)).where(start_at: time.dup)
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
          InvoiceMailer.delay(priority: 5).notify(invoice)
        end
        periods = Period.where(:user_id.in => organization.customers.not_centralized.map(&:id)).where(start_at: time.dup)
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
              InvoiceMailer.delay(priority: 5).notify(invoice)
            end
          end
        end
      end
      Invoice.archive
      puts "[#{Time.now}] maintenance:invoice:generate - END"
    end
  end
end

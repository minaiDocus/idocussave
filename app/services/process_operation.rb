# -*- encoding : UTF-8 -*-
class ProcessOperation
  def self.execute(banking_operations=nil)
    operations = banking_operations || Operation.not_processed.not_locked.asc(:date)

    if operations.count > 0
      preseizures = []

      operations.group_by do |operation|
        [operation.user, operation.pack, operation.bank_account]
      end.each do |group, operations|
        user         = group[0]
        pack         = group[1]
        bank_account = group[2]
        if pack || bank_account.try(:configured?)
          pack_report = initialize_pack_report(user, pack || bank_account)
          counter = pack_report.preseizures.count
          to_deliver_preseizures = []
          account_number_finder = AccountNumberFinderService.new(user, bank_account.try(:temporary_account).presence)

          operations.each do |operation|
            counter += 1
            preseizure = Pack::Report::Preseizure.new
            preseizure.organization    = user.organization
            preseizure.user            = user
            preseizure.report          = pack_report
            preseizure.operation       = operation
            preseizure.type            = 'FLUX'
            preseizure.date            = operation.date
            preseizure.position        = counter
            preseizure.operation_label = operation.label
            preseizure.category_id     = operation.category_id
            preseizure.save

            ### 1 ###
            account = Pack::Report::Preseizure::Account.new
            account.preseizure = preseizure
            account.type       = Pack::Report::Preseizure::Account.get_type('TTC') # TTC / HT / TVA
            account.number     = bank_account.try(:accounting_number) || 512000
            account.save

            entry = Pack::Report::Preseizure::Entry.new
            entry.account    = account
            entry.preseizure = preseizure
            if operation.amount < 0
              entry.type     = Pack::Report::Preseizure::Entry::CREDIT
            else
              entry.type     = Pack::Report::Preseizure::Entry::DEBIT
            end
            entry.number     = 1
            entry.amount     = operation.amount.abs
            entry.save

            ### 2 ###
            account = Pack::Report::Preseizure::Account.new
            account.preseizure = preseizure
            account.type       = Pack::Report::Preseizure::Account.get_type('TTC') # TTC / HT / TVA
            account.number     = account_number_finder.execute(operation.label)
            account.save

            entry = Pack::Report::Preseizure::Entry.new
            entry.account    = account
            entry.preseizure = preseizure
            if operation.amount < 0
              entry.type     = Pack::Report::Preseizure::Entry::DEBIT
            else
              entry.type     = Pack::Report::Preseizure::Entry::CREDIT
            end
            entry.number     = 1
            entry.amount     = operation.amount.abs
            entry.save

            preseizures << preseizure
            to_deliver_preseizures << preseizure
            operation.update_attribute(:processed_at, Time.now)
          end
          if pack_report.preseizures.not_delivered.not_locked.count > 0
            pack_report.update_attribute(:is_delivered, false)
          end
          to_deliver_preseizures.group_by(&:report).each do |_, pres|
            CreatePreAssignmentDeliveryService.new(pres, true).execute
          end
        else
          operations.each do |operation|
            operation.update_attribute(:is_locked, true)
          end
        end
      end

      preseizures
    end
  end

  def self.current_period_name
    Time.now.strftime("%Y%m")
  end

  def self.pack_name(user, object)
    if object.is_a?(Pack)
      object.name.sub(' all', '')
    else
      "#{user.code} #{object.journal} #{current_period_name}"
    end
  end

  def self.initialize_pack_report(user, object)
    name = pack_name(user, object)
    pack_report = Pack::Report.where(name: name).first
    unless pack_report
      pack_report = Pack::Report.new
      pack_report.organization = user.organization
      pack_report.user         = user
      pack_report.type         = 'FLUX'
      pack_report.name         = name
      pack_report.save
    end
    pack_report
  end
end
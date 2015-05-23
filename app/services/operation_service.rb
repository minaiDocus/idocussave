# -*- encoding : UTF-8 -*-
class OperationService
  def self.fetch(object, update=false)
    if object.class.to_s.in?(%w(User FiduceoRetriever))
      bank_accounts = object.bank_accounts
    else
      bank_accounts = Array(object)
    end
    bank_accounts.each do |bank_account|
      options = { account_id: bank_account.fiduceo_id }
      date = bank_account.operations.desc(:date).first.try(:date)
      if date
        options[:from_date] = (date - 5.days).strftime('%d/%m/%Y')
        options[:to_date]   = Date.today.strftime('%d/%m/%Y')
      end
      operations = FiduceoOperation.new(bank_account.user.fiduceo_id, options).operations || []
      operations.each do |temp_operation|
        operation = Operation.where(fiduceo_id: temp_operation.id).first
        if update && operation
          operation.bank_account = bank_account
          assign_attributes(operation, temp_operation)
          operation.save
        elsif !update && !operation
          operation = Operation.new
          operation.organization = bank_account.user.organization
          operation.user         = bank_account.user
          operation.bank_account = bank_account
          operation.fiduceo_id   = temp_operation.id
          assign_attributes(operation, temp_operation)
          operation.save
        end
      end
    end
  end

  def self.update_bank_account(bank_account)
    options = { account_id: bank_account.fiduceo_id }
    operation_ids = FiduceoOperation.new(bank_account.user.fiduceo_id, options).operations.map(&:id) || []
    bank_account.user.operations.where(:fiduceo_id.in => operation_ids).
      update_all(bank_account_id: bank_account.id, is_locked: !bank_account.configured?)
  end

  def self.assign_attributes(operation, temp_operation)
    operation.date             = temp_operation.date_op
    operation.value_date       = temp_operation.date_val
    operation.transaction_date = temp_operation.date_transac
    operation.label            = temp_operation.label
    operation.amount           = temp_operation.amount
    operation.comment          = temp_operation.comment
    operation.supplier_found   = temp_operation.supplier_found
    operation.type_id          = temp_operation.type_id
    operation.category_id      = temp_operation.category_id
    operation.category         = temp_operation.category
  end

  def self.process(banking_operations=nil)
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

          operations.each do |operation|
            counter += 1
            preseizure = Pack::Report::Preseizure.new
            preseizure.organization    = user.organization
            preseizure.user            = user
            preseizure.report          = pack_report
            preseizure.operation       = operation
            preseizure.type            = 'FLUX'
            preseizure.name            = pack_report.name
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
            account.number     = account_number(user, operation.label, bank_account.try(:temporary_account).presence)
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
          to_deliver_preseizures.group_by(&:report).each do |_, pres|
            CreatePreAssignmentDeliveryService.new(pres, true).execute
          end
          # For manual delivery
          if pack_report.preseizures.not_delivered.not_locked.count > 0
            pack_report.update_attribute(:is_delivered, false)
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

  def self.account_number(user, label, temporary_account='471000')
    number = nil
    if user.organization.ibiza.try(:is_configured?)
      # Ibiza accounting plan
      doc = parsed_open_accounting_plan(user.code)
      if doc
        result = doc.css('name').select { |name| label.match /#{Regexp.quote(name.content)}/i }.first
        number = result.parent.css('number').text if result
      end
    else
      # DB Accounting Plan
      if user.accounting_plan
        provider = user.accounting_plan.providers.select do |provider|
          label.match /#{Regexp.quote(provider.third_party_name)}/i
        end.first
        number = provider.third_party_account if provider
      end
    end
    number = temporary_account unless number.present?
    number
  end

  def self.parsed_open_accounting_plan(code)
    accounting_plan = parsed_accounting_plan(code)
    if accounting_plan
      closed_account = accounting_plan.css('closed').select{ |closed| closed.text == '1' }
      closed_account.each do |account|
        account.parent.remove
      end
    end
    accounting_plan
  end

  def self.parsed_accounting_plan(code)
    path = File.join([Rails.root, 'data', 'compta', 'mapping', "#{code}.xml"])
    if File.exist? path
      Nokogiri::XML(open(path))
    else
      nil
    end
  end
end

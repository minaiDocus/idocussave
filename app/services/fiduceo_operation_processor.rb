# -*- encoding : UTF-8 -*-
class FiduceoOperationProcessor
  def initialize(user)
    @user = user
    @ibiza = user.organization.ibiza
  end

  def process
    fiduceo_operation = FiduceoOperation.new @user.fiduceo_id
    operations = fiduceo_operation.operations

    if operations && operations.any?
      grouped_operations = operations.group_by do |operation|
        operation.account_id
      end

      preseizures = []
      grouped_operations.each do |account_id, operations|
        bank_account = @user.bank_accounts.valid.select do |bank_account|
          bank_account.fiduceo_id == account_id
        end.first
        if bank_account
          operations.sort! { |a,b| a.date <=> b.date }
          pack_report = find_or_create_pack_report(bank_account.journal)
          counter = pack_report.preseizures.count
          operations.each do |operation|
            preseizure = find_or_initialize_preseizure(operation.id)
            unless preseizure.persisted?
              counter += 1
              preseizure.name = pack_report.name
              preseizure.date = operation.date_op
              preseizure.position = counter
              preseizure.observation = [operation.label, operation.category].join(' - ')
              preseizure.category_id = operation.category_id
              preseizure.save
              preseizures << preseizure
              pack_report.preseizures << preseizure
              
              ####################### 1 #######################
              account           = Pack::Report::Preseizure::Account.new
              account.type      = Pack::Report::Preseizure::Account.get_type('TTC') # TTC / HT / TVA
              account.number    = bank_account.accounting_number
              preseizure.accounts << account
              account.save
              
              entry = Pack::Report::Preseizure::Entry.new
              amount = operation.amount
              if amount < 0
                entry.type = Pack::Report::Preseizure::Entry::CREDIT
              else
                entry.type = Pack::Report::Preseizure::Entry::DEBIT
              end
              entry.number = 1
              entry.amount = amount.abs
              account.entries << entry
              preseizure.entries << entry
              entry.save

              ####################### 2 #######################
              account           = Pack::Report::Preseizure::Account.new
              account.type      = Pack::Report::Preseizure::Account.get_type('TTC') # TTC / HT / TVA
              account.number    = account_number(operation.label)
              preseizure.accounts << account
              account.save
              
              entry = Pack::Report::Preseizure::Entry.new
              if amount < 0
                entry.type = Pack::Report::Preseizure::Entry::DEBIT
              else
                entry.type = Pack::Report::Preseizure::Entry::CREDIT
              end
              entry.number = 1
              entry.amount = amount.abs
              account.entries << entry
              preseizure.entries << entry
              entry.save
            end
          end
        end
      end
      if preseizures.any?
        grouped_preseizures = preseizures.group_by do |preseizure|
          preseizure.report
        end
        grouped_preseizures.each do |report, preseizures|
          report.is_delivered = false
          report.delivery_tried_at = nil
          report.delivery_message = ''
          report.save
          if @ibiza && @ibiza.is_configured? && @ibiza.is_auto_deliver
            @ibiza.export(preseizures)
          end
        end
      end
    end
  end

private

  def pack_name(journal='FLUX')
    "#{@user.code} #{journal} #{current_period_name}"
  end

  def current_period_name
    Time.now.strftime("%Y%m")
  end

  def find_or_create_pack_report(journal='FLUX')
    pack_report = Pack::Report.where(name: pack_name(journal)).first
    unless pack_report
      pack_report = Pack::Report.new
      pack_report.organization = @user.organization
      pack_report.user = @user
      pack_report.type = 'FLUX'
      pack_report.name = pack_name(journal)
      pack_report.save
      pack_report
    end
    pack_report
  end

  def find_or_initialize_preseizure(id)
    if (preseizure = Pack::Report::Preseizure.where(fiduceo_id: id).first)
      preseizure
    else
      Pack::Report::Preseizure.new(fiduceo_id: id, user_id: @user.id, type: 'FLUX')
    end
  end
  
  def client
    @client ||= Fiduceo::Client.new @user.fiduceo_id
  end

  def account_number(label)
    number = nil
    if @user.organization.ibiza.try(:is_configured?)
      # Ibiza accounting plan
      doc = parsed_accounting_plan(@user)
      if doc
        result = doc.css('name').select { |name| label.match /#{name.content}/ }.first
        number = result.parent.css('associate').content if result
      end
    else
      # DB Accounting Plan
      if @user.accounting_plan
        provider = @user.accounting_plan.providers.select do |provider|
          label.match /#{provider.third_party_name}/i
        end.first
        number = provider.third_party_account if provider
      end
    end
    number = '471000' unless number.present?
    number
  end

  def parsed_accounting_plan(code)
    path = File.join([Rails.root, 'data', 'compta', 'mapping', "#{code}.xml"])
    if File.exist? path
      Nokogiri::XML(open(path))
    else
      nil
    end
  end
end

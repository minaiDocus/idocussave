# -*- encoding : UTF-8 -*-
class FiduceoOperationProcessor
  def initialize(user)
    @user = user
  end

  def process
    operations = []
    per_page = 1000
    page = 1
    result = client.operations(page, per_page)
    if result
      operations_count = result['count'].to_i
      previous_operations_count = operations_count

      while operations.count < operations_count
        page += 1
        result = client.operations(page, per_page)
        if result
          previous_operations_count = operations.count
          operations += result['operation']
          operations.uniq!
          break if previous_operations_count == operations.count
        else
          break
        end
      end
    
      operations.sort! do |a,b|
        a['dateOp'] <=> b['dateOp']
      end

      if operations.count > 0
        preseizures_count = pack_report.preseizures.count
        operations.each_with_index do |operation, index|
          preseizure = find_or_initialize_preseizure(operation['id'])
          unless preseizure.persisted?
            preseizure.name = pack_report.pack_name
            preseizure.date = operation['dateOp']
            preseizure.position = preseizures_count + index + 1
            preseizure.amount = operation['amount'].to_f
            preseizure.currency = '€'
            preseizure.observation = operation['label']
            preseizure.save
            pack_report.preseizures << preseizure
            
            ####################### 1 #######################
            account           = Pack::Report::Preseizure::Account.new
            account.type      = Pack::Report::Preseizure::Account.get_type('TTC') # TTC / HT / TVA
            account.number    = 512000
            preseizure.accounts << account
            account.save
            
            entry = Pack::Report::Preseizure::Entry.new
            amount = operation['amount'].to_f
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
            account.number    = account_number(operation['label'])
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
        pack_report.preseizures
      end
    end
  end

private

  def pack_name
    "#{@user.code} FLUX #{current_period_name}"
  end

  def current_period_name
    Time.now.strftime("%Y%m")
  end

  def pack_report
    if @pack_report
      @pack_report
    else
      @pack_report = Pack::Report.where(name: pack_name).first
      unless @pack_report
        @pack_report = Pack::Report.new
        @pack_report.organization = @user.organization
        @pack_report.user = @user
        @pack_report.type = 'FLUX'
        @pack_report.name = pack_name
        @pack_report.save
        @pack_report
      end
      @pack_report
    end
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
          label.match /#{provider}/
        end.first
        number = provider.third_party_name if provider
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

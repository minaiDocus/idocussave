# -*- encoding : UTF-8 -*-
class FetchFiduceoData
  class << self
    def execute(retriever_id)
      new(retriever_id).execute
    end
    # TODO change with sidekiq worker system
    # handle_asynchronously :execute, priority: 2
  end

  def initialize(object)
    @retriever = if object.class == Retriever
      object
    else
      Retriever.find object
    end
  end

  # NOTE does not work with a connector with multiple capabilities
  def execute
    if @retriever.bank?
      data = client.retriever_bank_accounts(@retriever.fiduceo_id)
      if client.response.code == 200 && data[1].any?
        bank_accounts = @retriever.bank_accounts
        data[1].map do |bank_account_data|
          bank_account = bank_accounts.select { |bank_account| bank_account.number == bank_account_data.account_number }.first
          bank_account ||= BankAccount.new
          bank_account.user      ||= @retriever.user
          bank_account.retriever ||= @retriever
          bank_account.name      = bank_account_data.name
          bank_account.bank_name = @retriever.try(:service_name)
          bank_account.api_id    = bank_account_data.id
          bank_account.api_name  = 'fiduceo'
          bank_account.number    = bank_account_data.account_number
          bank_account.save
          bank_accounts -= [bank_account]
        end
        bank_accounts.each do |bank_account|
          bank_account.destroy
        end

        # TODO review the utility of 'update'
        update = false
        @retriever.bank_accounts.each do |bank_account|
          is_configured = bank_account.configured?
          options = { account_id: bank_account.fiduceo_id }
          date = bank_account.start_date
          if date
            last_operation_date = bank_account.operations.desc(:date).first.try(:date)
            if last_operation_date && date < (last_operation_date - 60.days)
              date = last_operation_date - 60.days
            end
            options[:from_date] = date.strftime('%d/%m/%Y')
            options[:to_date]   = Date.today.strftime('%d/%m/%Y')
          end
          operations = FiduceoOperation.new(bank_account.user.fiduceo_id, options).operations || []
          operations.each do |operation_data|
            operation = Operation.where(fiduceo_id: operation_data.id).first
            if update && operation
              operation.bank_account = bank_account
              assign_attributes(operation, operation_data)
              operation.save
            elsif !update && !operation
              operation = Operation.new
              operation.organization = bank_account.user.organization
              operation.user         = bank_account.user
              operation.bank_account = bank_account
              operation.api_id       = operation_data.id
              operation.api_name     = 'fiduceo'
              operation.is_locked    = !is_configured
              assign_attributes(operation, operation_data)
              operation.save
            end
          end
        end
      end
    else
      documents = []
      options = { retriever_id: @retriever.fiduceo_id }
      temp_document = @retriever.temp_documents.asc(:created_at).last
      if temp_document && temp_document.metadata['date'].present?
        options[:from_date] = temp_document.metadata['date'].strftime('%d/%m/%Y')
        options[:to_date]   = Date.today.strftime('%d/%m/%Y')
      end
      get_documents(options).each do |meta_document|
        unless @retriever.temp_documents.where(api_id: meta_document.id).present?
          document = client.document meta_document.id
          documents << document if client.response.code == 200
        end
      end
      documents.sort_by do |document|
        date = document['metadatas']['metadata'].select { |e| e['name'] == 'DATE' }.first['value']
        if date.present?
          Time.zone.parse(date).to_time
        else
          Time.now
        end
      end.each do |document|
        FiduceoDocument.new @retriever, document
      end
    end
  end

private

  def client
    @client ||= Fiduceo::Client.new @retriever.user.fiduceo_id
  end

  def self.assign_attributes(operation, operation_data)
    operation.date             = operation_data.date_op
    operation.value_date       = operation_data.date_val
    operation.transaction_date = operation_data.date_transac
    operation.label            = operation_data.label
    operation.amount           = operation_data.amount
    operation.comment          = operation_data.comment
    operation.supplier_found   = operation_data.supplier_found
    operation.type_id          = operation_data.type_id
    operation.category_id      = operation_data.category_id
    operation.category         = operation_data.category
  end

  def get_documents(options)
    page = 1
    per_page = 1000
    documents = []
    result = client.documents page, per_page, options
    if client.response.code == 200
      total = result[0]
      documents += result[1]
      if total > result[1].size
        page_number = (total / per_page).ceil
        while page < page_number
          page += 1
          result = client.documents page, per_page, options
          if client.response.code == 200
            documents += result[1]
          else
            raise Fiduceo::Errors::Unknown.new client.response.code
          end
        end
      end
    else
      raise Fiduceo::Errors::Unknown.new client.response.code
    end
    documents
  end
end

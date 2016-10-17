# -*- encoding : UTF-8 -*-
class ProcessRetrievedData
  class << self
    def execute(running_time=10.seconds)
      start_time = Time.now
      while(retrieved_data = RetrievedData.first)
        new(retrieved_data).execute
        break if Time.now > start_time + running_time
      end
    end
  end

  def initialize(retrieved_data)
    @retrieved_data = retrieved_data
  end

  def execute
    user = @retrieved_data.user
    @retrieved_data.content['connections'].each do |connection|
      bank_retriever = user.retrievers.where(api_id: connection['id'], type: 'bank').first
      if bank_retriever
        connection['accounts'].each do |account|
          bank_account = user.bank_accounts.where(api_id: account['id']).first
          if bank_account
            # NOTE 'deleted' type is datetime
            if account['deleted'].present?
              bank_account.operations.update_all(api_id: nil)
              bank_account.destroy
              bank_account = nil
            end
          else
            bank_account = BankAccount.new
            bank_account.user      = user
            bank_account.retriever = bank_retriever
            bank_account.api_id    = account['id']
            bank_account.bank_name = bank_retriever.service_name
            bank_account.name      = account['name']
            bank_account.number    = account['number']
            bank_account.save
          end

          if bank_account && account['transactions'].present?
            is_configured = bank_account.configured?
            account['transactions'].each do |transaction|
              operation = bank_account.operations.where(api_id: transaction['id'], api_name: 'budgea').first
              if operation
                assign_attributes(operation, transaction)
                operation.save if operation.changed?
              else
                # TODO - FIDUCEO MIGRATION reevaluate what field is needed for an exact match ?
                orphaned_operation = user.operations.where(
                  date:             transaction['date'],
                  value_date:       transaction['rdate'],
                  transaction_date: transaction['application_date'],
                  label:            transaction['original_wording'],
                  amount:           transaction['value'],
                  comment:          transaction['comment'],
                  type:             transaction['type'],
                  category_id:      transaction['id_category'],
                  # NOTE ids of fiduceo api may be still there
                  api_id:           nil
                ).first
                if orphaned_operation
                  orphaned_operation.bank_account = bank_account
                  orphaned_operation.api_id       = transaction['id']
                  orphaned_operation.save
                else
                  operation = Operation.new
                  operation.organization = user.organization
                  operation.user         = user
                  operation.bank_account = bank_account
                  operation.api_id       = transaction['id']
                  operation.api_name     = 'budgea'
                  operation.is_locked    = !is_configured
                  assign_attributes(operation, transaction)
                  operation.save
                end
              end
            end
          end
        end
        bank_retriever.update(sync_at: Time.parse(connection['last_update']))
        if bank_retriever.is_selection_needed
          bank_retriever.update(is_selection_needed: false)
          bank_retriever.wait_selection
        else
          bank_retriever.ready
        end
      end

      retriever = user.retrievers.where(api_id: connection['id'], type: 'provider').first
      if retriever
        is_new_document_present = false
        connection['subscriptions'].each do |subscription|
          if subscription['documents'].present?
            is_new_document_present = true
            client = Budgea::Client.new(retriever.user.budgea_account.access_token)
            subscription['documents'].sort_by do |document|
              Time.parse(document['timestamp'])
            end.each do |document|
              # TODO implement retry ?
              temp_file_path = client.get_file document['id']
              if client.response.code == 200
                RetrievedDocument.new(retriever, document, temp_file_path)
              else
                # TODO implement me
              end
            end
          end
        end
        retriever.update(sync_at: Time.parse(connection['last_update']))
        if retriever.is_selection_needed && is_new_document_present
          retriever.update(is_selection_needed: false)
          retriever.wait_selection
        else
          retriever.ready
        end
      end
      # TODO what does budgea send if there is no new data for a connection ?
    end

    @retrieved_data.destroy
    true
  end

private

  def assign_attributes(operation, transaction)
    # TODO review dates
    operation.date             = transaction['date']
    operation.value_date       = transaction['rdate']
    operation.transaction_date = transaction['application_date']
    operation.label            = transaction['original_wording']
    operation.amount           = transaction['value']
    operation.comment          = transaction['comment']
    operation.type             = transaction['type']
    operation.category_id      = transaction['id_category']
    operation.category         = BankOperationCategory.find(transaction['id_category']).try(:[], 'name')
  end
end

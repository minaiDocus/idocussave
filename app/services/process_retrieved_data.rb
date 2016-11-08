# -*- encoding : UTF-8 -*-
class ProcessRetrievedData
  class << self
    def execute(running_time=10.seconds)
      start_time = Time.now
      while(retrieved_data = RetrievedData.not_processed.first)
        new(retrieved_data, start_time + running_time).execute
        break if Time.now > start_time + running_time
      end
    end
  end

  def initialize(retrieved_data, run_until=nil)
    @retrieved_data = retrieved_data
    @run_until      = run_until
  end

  def execute
    user = @retrieved_data.user
    @retrieved_data.content['connections'].each do |connection|
      unless connection['id'].in?(@retrieved_data.processed_connection_ids)
        is_connection_ok = true
        retriever = user.retrievers.where(api_id: connection['id']).asc(:created_at).first
        if retriever
          is_new_transaction_present = false
          if connection['accounts'].present?
            connection['accounts'].each do |account|
              bank_account = user.bank_accounts.any_of(
                  {
                    api_id: account['id']
                  },
                  {
                    bank_name: retriever.service_name,
                    number:    account['number']
                  }
                ).first

              if bank_account
                # NOTE 'deleted' type is datetime
                if account['deleted'].present?
                  bank_account.operations.update_all(api_id: nil)
                  bank_account.destroy
                  bank_account = nil
                else
                  bank_account.api_id = account['id']
                  bank_account.name   = account['name']
                  bank_account.save if bank_account.changed?
                end
              else
                bank_account = BankAccount.new
                bank_account.user      = user
                bank_account.retriever = retriever
                bank_account.api_id    = account['id']
                bank_account.bank_name = retriever.service_name
                bank_account.name      = account['name']
                bank_account.number    = account['number']
                bank_account.save
              end

              if bank_account && account['transactions'].present?
                is_new_transaction_present = true
                is_configured = bank_account.configured?
                account['transactions'].each do |transaction|
                  operation = bank_account.operations.where(api_id: transaction['id'], api_name: 'budgea').first
                  if operation
                    assign_attributes(operation, transaction)
                    operation.save if operation.changed?
                  else
                    orphaned_operation = user.operations.where(
                      date:       transaction['date'],
                      value_date: transaction['application_date'],
                      label:      transaction['original_wording'],
                      amount:     transaction['value'],
                      comment:    transaction['comment'],
                      api_id:     nil
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
          end

          is_new_document_present = false
          unless retriever.bank?
            if connection['subscriptions'].present?
              errors = []
              connection['subscriptions'].each do |subscription|
                if subscription['documents'].present?
                  client = Budgea::Client.new(retriever.user.budgea_account.access_token)
                  subscription['documents'].sort_by do |document|
                    Time.parse(document['date'])
                  end.each do |document|
                    unless retriever.temp_documents.where(api_id: document['id']).first
                      tries = 1
                      is_success = false
                      error = nil
                      while tries <= 3 && !is_success
                        sleep(tries) if tries > 1
                        temp_file_path = client.get_file document['id']
                        begin
                          if client.response.code == 200
                            RetrievedDocument.new(retriever, document, temp_file_path)
                            is_success = true
                            is_new_document_present = true
                          end
                        rescue Errno::ENOENT => e
                          error = e
                        end
                        tries += 1
                      end
                      unless is_success
                        is_connection_ok = false
                        if client.response.code == 200
                          errors << "[#{connection['id']}] Document '#{document['id']}' cannot process : [#{error.class}] #{error.message}"
                        else
                          errors << "[#{connection['id']}] Document '#{document['id']}' cannot be downloaded : [#{client.response.code}] #{client.response.body}"
                        end
                      end
                    end
                  end
                end
              end

              if errors.present?
                if @retrieved_data.error_message.present?
                  @retrieved_data.error_message += errors.join("\n")
                else
                  @retrieved_data.error_message = errors.join("\n")
                end
                @retrieved_data.save
                @retrieved_data.error
                retriever.update(error_message: "Certains documents n'ont pas pu être récupérés.")
                retriever.error
              end
            end
          end

          case connection['error']
          when 'wrongpass'
            retriever.update(
              is_new_password_needed: true,
              error_message: 'Mot de passe incorrecte.'
            )
            retriever.error
          when 'additionalInformationNeeded'
            retriever.ready if retriever.error?
            retriever.waiting_additionnal_info
          when 'websiteUnavailable'
            retriever.update(error_message: 'Site web indisponible.')
            retriever.error
          when 'bug'
            retriever.update(error_message: 'Service indisponible.')
            retriever.error
          else
            retriever.ready if is_new_document_present || is_new_transaction_present
          end

          retriever.update(sync_at: Time.parse(connection['last_update']))
          if retriever.is_selection_needed && (is_new_document_present || is_new_transaction_present) && retriever.wait_selection
            retriever.update(is_selection_needed: false)
          end
        end

        if is_connection_ok
          @retrieved_data.processed_connection_ids << connection['id']
          @retrieved_data.save
        end

        break if @run_until && @run_until < Time.now
      end
    end

    if @retrieved_data.error?
      addresses = Array(Settings.notify_errors_to)
      if addresses.size > 0
        NotificationMailer.notify(
          addresses,
          '[iDocus] Erreur lors du traitement des notifications Budgea',
          @retrieved_data.error_message).deliver
      end
      @retrieved_data.error_message
    else
      @retrieved_data.processed
    end
  end

private

  def assign_attributes(operation, transaction)
    operation.date        = transaction['date']
    operation.value_date  = transaction['application_date']
    operation.label       = transaction['original_wording']
    operation.amount      = transaction['value']
    operation.comment     = transaction['comment']
    operation.type        = transaction['type']
    operation.category_id = transaction['id_category']
    operation.category    = BankOperationCategory.find(transaction['id_category']).try(:[], 'name')
  end
end

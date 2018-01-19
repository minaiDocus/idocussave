# -*- encoding : UTF-8 -*-
class ProcessRetrievedData
  def initialize(retrieved_data, run_until=nil)
    @retrieved_data = retrieved_data
    @run_until      = run_until
  end

  def execute
    logger.info "[#{@retrieved_data.user.code}][RetrievedData:#{@retrieved_data.id}] start"
    start_time = Time.now
    user = @retrieved_data.user
    connections = @retrieved_data.json_content['connections']
    if connections.present?
      connections.each do |connection|
        unless connection['id'].in?(@retrieved_data.processed_connection_ids)
          is_connection_ok = true
          retriever = user.retrievers.where(budgea_id: connection['id']).order(created_at: :asc).first
          if retriever
            is_new_transaction_present = false
            new_operations_count = 0
            if connection['accounts'].present?
              connection['accounts'].each do |account|
                bank_accounts = if retriever.connector.is_fiduceo_active?
                  user.sandbox_bank_accounts
                else
                  user.bank_accounts
                end
                bank_account = bank_accounts.where(
                  'api_id = ? OR (name = ? AND number = ?)',
                  account['id'],
                  account['name'],
                  account['number']
                ).first

                if bank_account
                  # NOTE 'deleted' type is datetime
                  if account['deleted'].present?
                    if retriever.connector.is_fiduceo_active?
                      bank_account.sandbox_operations.update_all(api_id: nil)
                    else
                      bank_account.operations.update_all(api_id: nil)
                    end
                    bank_account.destroy
                    bank_account = nil
                  else
                    bank_account.retriever = retriever
                    bank_account.api_id    = account['id']
                    bank_account.api_name  = 'budgea'
                    bank_account.name      = account['name']
                    bank_account.type_name = account['type']
                    bank_account.save if bank_account.changed?
                  end
                else
                  bank_account = if retriever.connector.is_fiduceo_active?
                    SandboxBankAccount.new
                  else
                    BankAccount.new
                  end
                  bank_account.user      = user
                  bank_account.retriever = retriever
                  bank_account.api_id    = account['id']
                  bank_account.bank_name = retriever.service_name
                  bank_account.name      = account['name']
                  bank_account.number    = account['number']
                  bank_account.type_name = account['type']
                  bank_account.save
                end

                if bank_account && account['transactions'].present?
                  is_new_transaction_present = true
                  account['transactions'].each do |transaction|
                    operations = if retriever.connector.is_fiduceo_active?
                      bank_account.sandbox_operations
                    else
                      bank_account.operations
                    end
                    operation = operations.where(api_id: transaction['id'], api_name: 'budgea').first
                    if operation
                      if transaction['deleted'].present? && operation.processed_at.nil?
                        operation.destroy
                      else
                        assign_attributes(bank_account, operation, transaction)
                        operation.save if operation.changed?
                      end
                    else
                      orphaned_operation = find_orphaned_operation(bank_account, transaction)
                      if orphaned_operation
                        if retriever.connector.is_fiduceo_active?
                          orphaned_operation.sandbox_bank_account = bank_account
                        else
                          orphaned_operation.bank_account = bank_account
                          new_operations_count += 1 unless orphaned_operation.processed_at.present?
                        end
                        assign_attributes(bank_account, orphaned_operation, transaction)
                        orphaned_operation.api_id = transaction['id']
                        orphaned_operation.save

                      elsif transaction['deleted'].nil?
                        operation = if retriever.connector.is_fiduceo_active?
                          SandboxOperation.new(sandbox_bank_account_id: bank_account.id)
                        else
                          Operation.new(bank_account_id: bank_account.id)
                        end
                        operation.organization = user.organization
                        operation.user         = user
                        operation.api_id       = transaction['id']
                        operation.api_name     = 'budgea'
                        assign_attributes(bank_account, operation, transaction)
                        operation.save

                        new_operations_count += 1
                      end
                    end
                  end
                end
              end
            end

            initial_documents_count = retriever.temp_documents.count
            initial_sandbox_documents_count = retriever.sandbox_documents.count

            unless retriever.bank?
              if connection['subscriptions'].present?
                errors = []
                connection['subscriptions'].each do |subscription|
                  if subscription['documents'].present?
                    client = Budgea::Client.new(retriever.user.budgea_account.access_token)
                    subscription['documents'].select do |document|
                      retriever.service_name.in?(['Nespresso', 'Online.net']) && document['date'].nil? ? false : true
                    end.sort_by do |document|
                      document['date'].present? ? Time.parse(document['date']) : Time.local(1970)
                    end.each do |document|
                      already_exist = if retriever.connector.is_fiduceo_active?
                        retriever.sandbox_documents.where(api_id: document['id']).first
                      else
                        retriever.temp_documents.where(api_id: document['id']).first
                      end
                      unless already_exist
                        tries = 1
                        is_success = false
                        error = nil
                        while tries <= 3 && !is_success
                          sleep(tries) if tries > 1
                          temp_file_path = client.get_file document['id']
                          begin
                            if client.response.code == 200
                              if retriever.connector.is_fiduceo_active?
                                sandbox_document = SandboxDocument.new
                                sandbox_document.user               = retriever.user
                                sandbox_document.retriever          = retriever
                                sandbox_document.api_id             = document['id']
                                sandbox_document.retrieved_metadata = document
                                sandbox_document.content            = open(temp_file_path)
                                sandbox_document.save
                              else
                                RetrievedDocument.new(retriever, document, temp_file_path)
                              end
                              is_success = true
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

            new_documents_count = (retriever.temp_documents.count - initial_documents_count)
            new_sandbox_documents_count = (retriever.sandbox_documents.count - initial_sandbox_documents_count)
            is_new_document_present = new_documents_count > 0
            is_new_document_present ||= new_sandbox_documents_count > 0

            case connection['error']
            when 'wrongpass'
              error_message = connection['error_message'].presence || 'Mot de passe incorrect.'
              retriever.update(
                is_new_password_needed: true,
                budgea_error_message: error_message
              )
              retriever.fail_budgea_connection

              RetrieverNotification.new(retriever).notify_wrong_pass
            when 'additionalInformationNeeded'
              retriever.success_budgea_connection if retriever.budgea_connection_failed?
              if connection['fields'].present?
                retriever.update(budgea_additionnal_fields: connection['fields'])
                retriever.pause_budgea_connection
              end

              RetrieverNotification.new(retriever).notify_info_needed
            when 'actionNeeded'
              retriever.update budgea_error_message: 'Veuillez confirmer les nouveaux termes et conditions.'
              retriever.fail_budgea_connection

              RetrieverNotification.new(retriever).notify_action_needed
            when 'websiteUnavailable'
              retriever.update(budgea_error_message: 'Site web indisponible.')
              retriever.fail_budgea_connection

              RetrieverNotification.new(retriever).notify_website_unavailable
            when 'bug'
              retriever.update(budgea_error_message: 'Service indisponible.')
              retriever.fail_budgea_connection

              RetrieverNotification.new(retriever).notify_bug
            else
              if is_new_document_present || is_new_transaction_present || retriever.error?
                retriever.success_budgea_connection

                RetrieverNotification.new(retriever).notify_new_documents new_documents_count if new_documents_count > 0
                RetrieverNotification.new(retriever).notify_new_operations new_operations_count if new_operations_count > 0
              end
            end

            retriever.update(sync_at: Time.parse(connection['last_update'])) if connection['last_update'].present?
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
    end

    logger.info "[#{user.code}][RetrievedData:#{@retrieved_data.id}] done: #{(Time.now - start_time).round(3)} sec"

    if @retrieved_data.error?
      addresses = Array(Settings.first.try(:notify_errors_to))
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

  def find_orphaned_operation(bank_account, transaction)
    operations = if bank_account.retriever.connector.is_fiduceo_active?
      bank_account.user.sandbox_operations
    else
      bank_account.user.operations
    end

    orphaned_operation = operations.where(
      date:       transaction['date'],
      value_date: transaction['rdate'],
      amount:     transaction['value'],
      comment:    transaction['comment'],
      api_id:     nil
    )

    if bank_account.type_name != 'card' && transaction['type'] == 'deferred_card'
      orphaned_operation = orphaned_operation.where(
        operations.arel_table[:label].eq(transaction['original_wording']).or(
          operations.arel_table[:label].eq('[CB] ' + transaction['original_wording'])
        )
      )
    else
      orphaned_operation = orphaned_operation.where(label: transaction['original_wording'])
    end

    orphaned_operation.first
  end

  def assign_attributes(bank_account, operation, transaction)
    operation.date        = transaction['date']
    operation.value_date  = transaction['rdate']
    if bank_account.type_name != 'card' && transaction['type'] == 'deferred_card'
      operation.label     = '[CB] ' + transaction['original_wording']
    else
      operation.label     = transaction['original_wording']
    end
    operation.amount      = transaction['value']
    operation.comment     = transaction['comment']
    operation.type_name   = transaction['type']
    operation.category_id = transaction['id_category']
    operation.category    = BankOperationCategory.find(transaction['id_category']).try(:[], 'name')
    operation.deleted_at  = Time.parse(transaction['deleted']) if transaction['deleted'].present?
    if operation.class == Operation && operation.processed_at.nil?
      operation.is_coming = transaction['coming']
      if lock_operation?(bank_account, operation)
        operation.is_locked = true
      else
        operation.is_locked = !(bank_account.is_used && bank_account.configured?)
      end
    end
  end

  def lock_operation?(bank_account, operation)
    (bank_account.start_date.present? && operation.date < bank_account.start_date) ||
      operation.date < Date.parse('2017-01-01') ||
      operation.is_coming ||
      is_operation_old?(bank_account, operation)
  end

  def is_operation_old?(bank_account, operation)
    bank_account.created_at < 1.month.ago &&
      operation.date < Date.today.beginning_of_month &&
      operation.date < 1.week.ago.to_date
  end

  def logger
    @logger ||= Logger.new("#{Rails.root}/log/#{Rails.env}_processing.log")
  end
end

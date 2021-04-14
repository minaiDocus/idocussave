# -*- encoding : UTF-8 -*-
class DataProcessor::RetrievedData
  attr_accessor :retriever

  SYNCED_BUDGEA_LISTS = ["USER_SYNCED", "USER_DELETED", "CONNECTION_SYNCED", "CONNECTION_DELETED", "ACCOUNTS_FETCHED"].freeze

  def self.execute(retrieved_param, type_synced=nil, user=nil)
    DataProcessor::RetrievedData.new(retrieved_param, type_synced, user).execute
  end

  def self.process(retrieved_data_id)
    UniqueJobs.for "ProcessRetrievedData-#{retrieved_data_id}" do
      retrieved_data = RetrievedData.find retrieved_data_id
      DataProcessor::RetrievedData.new(retrieved_data).execute if retrieved_data.not_processed?
    end
  end

  def initialize(retrieved_data, type_synced=nil, user=nil)
    @retrieved_data = retrieved_data
    @type_synced    = type_synced
    @user           = user.presence || @retrieved_data.try(:user)
  end

  def execute
    process_retrieved_data if @retrieved_data
  end

  def execute_with(type='operation', parser_ids = [], min_date=nil, max_date=nil)
    @parser_ids     = parser_ids #parser_ids must be a list of accounts (bank_accounts) ids, or a list of budgea_ids (connections)
    @min_date       = min_date
    @max_date       = max_date

    budgea_transaction_fetcher(type)
  end

  private

  def process_retrieved_data
    if SYNCED_BUDGEA_LISTS.include?(@type_synced)
      json_content = @retrieved_data
    elsif @retrieved_data.json_content
      json_content = @retrieved_data.json_content
    end

    parse_of json_content if (json_content.present? && (json_content[:success] || @type_synced.present?))
    finalize json_content unless @type_synced.present?
  end

  def budgea_transaction_fetcher(type='operation')
    @new_operations_count     = 0
    @operations_fetched_count = 0
    @deleted_operations_count = 0

    new_documents_count       = 0
    total_documents           = 0
    document_errors           = []

    log_message = "------------[#{type} - #{@user.try(:code)} - #{@parser_ids.to_s} - #{@min_date} - #{@max_date}]---------------\n"

    if client && @user
      if @min_date && @max_date && @parser_ids.present?
        #parser_ids and parsed_data must be a list of accounts (bank_accounts) ids, or a list of budgea_ids (connections)
        if type == 'operation'
          parsed_data = client.get_accounts
        else
          parsed_data = client.get_all_connections.try(:[], 'connections')
        end

        if parsed_data.present? && !(parsed_data =~ /unauthorized/)
          parsed_data.each do |data|
            next unless @parser_ids.include? "#{data['id']}"

            if type == 'operation'
              @connection_id = data['id_connection']
            else
              @connection_id = data['id']
            end

            if retriever
              if type == 'operation'
                transactions = client.get_transactions data['id'], @min_date, @max_date
                bank_account = get_bank_account_of data

                make_operation_of(bank_account, transactions) if bank_account && transactions.present?
              else
                documents = client.get_documents data['id'], @min_date, @max_date
                total_documents += documents.try(:size).to_i

                if documents.any?
                  documents.select do |document|
                    retriever.service_name.in?(['Nespresso', 'Online.net']) && document['date'].nil? ? false : true
                  end.sort_by do |document|
                    document['date'].present? ? Time.parse(document['date']) : Time.local(1970)
                  end.each do |document|
                    file_state = Retriever::RetrievedDocument.process_file(retriever.id, document, 0)

                    if !file_state[:success]
                      if file_state[:return_object].try(:status).present?
                        document_errors << "Document '#{document['id']}' cannot be downloaded : [#{file_state[:return_object].try(:status)}] #{file_state[:return_object].try(:body)}"
                      else
                        document_errors << "Document '#{document['id']}' cannot be downloaded : #{file_state[:return_object].to_s}"
                      end
                    else
                      new_documents_count += 1
                    end
                  end
                end
              end
            else
              log_message += "[BudgeaTransactionFetcher][#{@user.code}] - No retriever found, for connection id: #{data['id_connection']}\n"
            end
          end
        else
          log_message += "[BudgeaTransactionFetcher][#{@user.code}] - No Ids found! OR Unauthorized => #{parsed_data.to_s}"
          System::Log.info('budgea_fetch_processing', log_message)
          return log_message
        end
      else
        log_message += "[BudgeaTransactionFetcher][#{@user.code}] - Parameters invalid!"
        System::Log.info('budgea_fetch_processing', log_message)
        return log_message
      end
    else
      log_message += "[BudgeaTransactionFetcher][#{@user.try(:code)}] - Budgea client invalid! - no budgea account configured for the user"
      System::Log.info('budgea_fetch_processing', log_message)
      return log_message
    end

    if document_errors.any?
      document_errors.each do |error|
        log_message += "[BudgeaTransactionFetcher] - #{error.to_s} \n"
      end
    end

    log_message += "[BudgeaTransactionFetcher][#{@user.try(:code)}] - New documents: #{new_documents_count} / Total documents fetched: #{total_documents} / New operations: #{@new_operations_count} / Deleted operations: #{@deleted_operations_count} / Total operations fetched: #{@operations_fetched_count}"
    System::Log.info('budgea_fetch_processing', log_message)
    return log_message
  end

  def parse_of(json_content)
    if @type_synced.nil? || (@type_synced.present? && @type_synced == 'USER_SYNCED')
      connections = @type_synced.present? ? json_content['connections'] : json_content[:content]['connections']

      connections.each do |connection|
        next if connection['id'].in?(@retrieved_data.processed_connection_ids) unless @type_synced.present?

        execute_process connection
      end
    elsif json_content['connection'].present?
      execute_process json_content['connection']
    elsif @type_synced == 'CONNECTION_DELETED'
      System::Log.info('webhook', "[#{@type_synced}] =========== User_id [#{@user.id}] =================== #{json_content} ============================ BudgeaName [#{retriever.service_name}] =====================") if retriever
      @connection_id    = json_content['id']

      add_webhook(retriever, json_content)
      Retriever::DestroyBudgeaConnection.execute(retriever) if retriever && retriever.try(:destroy_connection)
    elsif @type_synced == 'USER_DELETED' && @user.budgea_account
      retrievers = @user.retrievers

      retrievers.each do |retr|
        System::Log.info('webhook', "[#{@type_synced}] =========== User_id [#{@user.id}] =================== RetID [#{retr.id}] ============================ BudgeaName [#{retr.service_name}] =====================") if retr
        Retriever::DestroyBudgeaConnection.execute(retr) if retr && retr.try(:destroy_connection)

        add_webhook(retr, json_content)
      end

      @user.budgea_account.destroy
    end

    webhook_notification(json_content)
  end

  def execute_process(connection)
    @is_connection_ok = true
    @connection_id    = connection['id']

    connection.merge!("source"=>"ProcessRetrievedData")

    process connection if retriever

    if @is_connection_ok && @type_synced.nil?
      @retrieved_data.processed_connection_ids << connection['id']
      @retrieved_data.save
    end
  end

  def process(connection)
    System::Log.info('webhook', "[#{@type_synced}] =========== User_id [#{@user.id}] =================== RetID [#{retriever.id}] ============================ BudgeaName [#{retriever.service_name}] =====================")

    @is_new_transaction_present = false
    @new_operations_count       = 0

    if connection['accounts'].present?
      connection['accounts'].each do |account|
        bank_account = update_or_create_bank_of account
        make_operation_of(bank_account, account['transactions']) if bank_account && account['transactions'].present?  
      end
    end

    initial_documents_count = retriever.temp_documents.count

    get_document_file_of(connection) if retriever.provider? && retriever.journal.present? && connection['subscriptions'].present?

    @new_documents_count     = (retriever.temp_documents.count - initial_documents_count)
    @is_new_document_present = @new_documents_count > 0

    if retriever.sync_at.blank? || retriever.sync_at <= 3.minutes.ago
      retriever.resume_me
      retriever.update(sync_at: Time.now)
    end

    notify connection

    add_webhook(retriever, connection)

    if retriever.is_selection_needed && (@is_new_document_present || @is_new_transaction_present)
      retriever.update(is_selection_needed: false) if retriever.wait_selection
    end
  end

  def finalize(json_content)
    if (!json_content[:success] && json_content[:content] != 'File not found') || @retrieved_data.error?
      if !json_content[:success]
        @retrieved_data.update(error_message: json_content[:content].to_s)
        @retrieved_data.error
        @retrieved_data.reload
      end

      # addresses = Array(Settings.first.try(:notify_errors_to))
      # if addresses.size > 0
      #   NotificationMailer.notify(
      #     addresses,
      #     '[iDocus] Erreur lors du traitement des notifications Budgea',
      #     "#{@retrieved_data.id.to_s} - #{@retrieved_data.error_message}").deliver
      # end
      System::Log.info('retrieved_data', "[#{@user.code}][RetrievedData:#{@retrieved_data.id}] Error: #{@retrieved_data.error_message}")
      @retrieved_data.error_message
    else
      @retrieved_data.processed if json_content[:success] || !@retrieved_data.cloud_content.attached?
    end
  end

  def update_or_create_bank_of(account)
    bank_account = get_bank_account_of account

    # NOTE 'deleted' type is datetime
    if bank_account && account['deleted'].present?
      bank_account.operations.update_all(api_id: nil)
      bank_account.destroy
      bank_account = nil
    else
      bank_account                   = bank_account || BankAccount.new
      bank_account.user              = @user
      bank_account.retriever         = retriever
      bank_account.api_id            = account['id']
      bank_account.bank_name         = retriever.service_name
      bank_account.name              = account['name']
      bank_account.number            = account['number']
      bank_account.type_name         = account['type']
      bank_account.original_currency = account['currency'].try(:to_unsafe_h)
      bank_account.api_name          = 'budgea'
      is_new                         = !bank_account.persisted?

      if bank_account.save
        historic = @user.retrievers_historics.where(retriever_id: retriever.id).first
        historic.update(banks_count: (historic.banks_count.to_i + 1)) if historic && is_new
      end
    end

    bank_account
  end

  def get_document_file_of(connection)
    errors = []
    connection['subscriptions'].each do |subscription|
      if subscription['documents'].present?
        subscription['documents'].select do |document|
          retriever.service_name.in?(['Nespresso', 'Online.net']) && document['date'].nil? ? false : true
        end.sort_by do |document|
          document['date'].present? ? Time.parse(document['date']) : Time.local(1970)
        end.each do |document|
          file_state = Retriever::RetrievedDocument.process_file(retriever.id, document, 0)

          if !file_state[:success]
            @is_connection_ok = false
            if file_state[:return_object].try(:status).present?
              errors << "[#{connection['id']}] Document '#{document['id']}' cannot be downloaded : [#{file_state[:return_object].try(:status)}] #{file_state[:return_object].try(:body)}"
            else
              errors << "[#{connection['id']}] Document '#{document['id']}' cannot be downloaded : #{file_state[:return_object].to_s}"
            end
          end
        end
      end
    end

    if errors.present?
      unless @type_synced.present?
        if @retrieved_data.error_message.present?
          @retrieved_data.error_message += errors.join("\n")
        else
          @retrieved_data.error_message = errors.join("\n")
        end
        @retrieved_data.save
        @retrieved_data.error
      end

      retriever.update(error_message: "Certains documents n'ont pas pu être récupérés.")
      retriever.error
    end
  end

  def notify(connection)
    if retriever.reload.budgea_connection_successful?
      Notifications::Retrievers.new(retriever).notify_new_documents(@new_documents_count) if @new_documents_count > 0
      Notifications::Retrievers.new(retriever).notify_new_operations(@new_operations_count) if @new_operations_count > 0
    end
  end

  def make_operation_of(bank_account, transactions)
    @is_new_transaction_present = true

    transactions.each do |transaction|
      @operations_fetched_count = @operations_fetched_count.to_i + 1

      operation = bank_account.operations.where(api_id: transaction['id'], api_name: 'budgea').first

      if operation
        if transaction['deleted'].present? && operation.processed_at.nil?
          operation.destroy

          @deleted_operations_count = @deleted_operations_count.to_i + 1
        elsif operation.processed_at.nil?
          assign_attributes(bank_account, operation, transaction)
          operation.save if operation.changed?
        end
      else
        orphaned_operation = find_orphaned_operation(bank_account, transaction)

        if orphaned_operation
          orphaned_operation.bank_account = bank_account
          @new_operations_count += 1 unless orphaned_operation.processed_at.present?

          assign_attributes(bank_account, orphaned_operation, transaction)
          orphaned_operation.api_id = transaction['id']
          orphaned_operation.save
        elsif transaction['deleted'].nil?
          operation              = Operation.new(bank_account_id: bank_account.id)
          operation.organization = @user.organization
          operation.user         = @user
          operation.api_id       = transaction['id']
          operation.api_name     = 'budgea'
          assign_attributes(bank_account, operation, transaction)
          operation.save

          historic = @user.retrievers_historics.where(retriever_id: retriever.id).first
          historic.update(operations_count: (historic.operations_count.to_i + 1)) if historic

          @new_operations_count += 1
        end
      end
    end
  end

  def find_orphaned_operation(bank_account, transaction)
    operations = bank_account.user.operations

    orphaned_operation = operations.where(
      date:       transaction['date'],
      value_date: transaction['rdate'],
      amount:     set_transaction_value(bank_account, transaction),
      comment:    transaction['comment'].presence || '',
      api_id:     nil
    )

    if bank_account.type_name != 'card' && transaction['type'] == 'deferred_card'
      orphaned_operation = orphaned_operation.where(
        operations.arel_table[:label].eq(transaction['original_wording']).or(
          operations.arel_table[:label].eq('[CB] ' + transaction['original_wording'])
        )
      )
    else
      label = [transaction['original_wording']]
      label << bank_account.number if bank_account.type_name == 'card'
      orphaned_operation = orphaned_operation.where(label: [transaction['original_wording'], label.join(' ')])
    end

    orphaned_operation.first
  end

  def assign_attributes(bank_account, operation, transaction)
    operation.date        = transaction['date']
    operation.value_date  = transaction['rdate']
    operation.currency    = bank_account.original_currency

    if bank_account.type_name != 'card' && transaction['type'] == 'deferred_card'
      operation.label     = '[CB] ' + transaction['original_wording']
    else
      label = [transaction['original_wording']]
      label << bank_account.number if bank_account.type_name == 'card'
      operation.label     = label.join(' ')
    end

    operation.amount      = set_transaction_value(bank_account, transaction)
    operation.comment     = transaction['comment'] if transaction['comment'].present?
    operation.type_name   = transaction['type']
    operation.category_id = transaction['id_category']
    operation.category    = Transaction::BankOperationCategory.find(transaction['id_category']).try(:[], 'name')
    operation.deleted_at  = Time.parse(transaction['deleted']) if transaction['deleted'].present?

    if operation.class == Operation && operation.processed_at.nil?
      operation.is_coming = transaction['coming']
      _is_duplicated = is_duplicate?(bank_account, operation)
      if _is_duplicated || operation.to_lock?
        operation.is_locked = true
        operation.comment = 'Locked for duplication' if _is_duplicated
      else
        operation.is_locked = !(bank_account.is_used && bank_account.configured?)
      end
    end
  end

  def is_duplicate?(bank_account, operation)
    bank_account.operations.where.not(api_name: 'budgea').where(amount: operation.amount, date: operation.date).count > 0
  end

  def set_transaction_value(bank_account, transaction)
    if (transaction['value'].nil? && bank_account.bank_name.downcase == 'paypal rest api')
      transaction['gross_value'] + transaction['commission'] if (transaction['gross_value'].present? && transaction['commission'].present?)
    else
      transaction['value']
    end
  end

  def client
    token = @user.try(:budgea_account).try(:access_token)

    unless @client
      @client = token.nil? ? nil : Budgea::Client.new(token)
    end
    @client
  end

  def retriever
    return @retriever if @retriever && @retriever.budgea_id == @connection_id && @retriever.user == @user

    @retriever = @user.retrievers.where(budgea_id: @connection_id).where.not(state: 'destroying').order(created_at: :asc).first

    @retriever
  end

  def get_bank_account_of(account)
    @user.bank_accounts.where('api_id = ? OR (bank_name = ? AND name = ? AND number = ?)', account['id'], retriever.service_name, account['name'], account['number']).first
  end

  def add_webhook(retriever, contents)
    whook              = Archive::WebhookContent.new

    whook.synced_date  = Time.now
    whook.synced_type  = @type_synced
    whook.json_content = contents
    whook.retriever    = retriever

    whook.save
  end

  def webhook_notification(json_content)
    log_document = {
      subject: "[DataProcessor::RetrievedData] retrieved data webhook #{@type_synced}",
      name: "RetrievedDataWebhook",
      error_group: "[Retrieved Data Webhook] : Data for - #{@type_synced}",
      erreur_type: "Data for - #{@type_synced}",
      date_erreur: Time.now.strftime('%Y-%m-%d %H:%M:%S'),
      more_information: { user_code: @user.code, type_synced: @type_synced }
    }

    ErrorScriptMailer.error_notification(log_document, { attachements: [{name: 'json_content.json', file: json_content.try(:to_unsafe_h).to_s}] }).deliver
  end
end
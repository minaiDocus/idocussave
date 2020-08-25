# -*- encoding : UTF-8 -*-
class ProcessRetrievedData

  def self.process(retrieved_data_id)
    UniqueJobs.for "ProcessRetrievedData-#{retrieved_data_id}" do
      retrieved_data = RetrievedData.find retrieved_data_id
      ProcessRetrievedData.new(retrieved_data).execute if retrieved_data.not_processed?
    end
  end

  def initialize(retrieved_data, run_until=nil, user=nil)
    @retrieved_data = retrieved_data
    @run_until      = run_until
    @user           = user.presence || @retrieved_data.try(:user)
  end

  def execute
    process_retrieved_data if @retrieved_data
  end

  def execute_with(account_ids = [], min_date=nil, max_date=nil)
    @account_ids    = account_ids
    @min_date       = min_date
    @max_date       = max_date

    budgea_transaction_fetcher
  end

  private

  def process_retrieved_data
    LogService.info('processing', "[#{@retrieved_data.user.code}][RetrievedData:#{@retrieved_data.id}] start")
    start_time   = Time.now

    json_content = @retrieved_data.json_content
    parse_of json_content if json_content.present? && json_content[:success]
    finalize json_content

    LogService.info('processing', "[#{@user.code}][RetrievedData:#{@retrieved_data.id}] done: #{(Time.now - start_time).round(3)} sec")
  end

  def budgea_transaction_fetcher
    @new_operations_count     = 0
    @operations_fetched_count = 0
    @deleted_operations_count = 0


    log_message = "------------[#{@user.try(:code)} - #{@account_ids.to_s} - #{@min_date} - #{@max_date}]---------------\n"

    if client && @user
      if @min_date && @max_date && @account_ids.present?
        @accounts = client.get_accounts

        if @accounts.present? && !(@accounts =~ /unauthorized/)
          @accounts.each do |account|
            next unless @account_ids.include? "#{account['id']}"

            @connection_id = account['id_connection']
            if retriever
              transactions = client.get_transactions account['id'], @min_date, @max_date

              bank_account = get_bank_account_of account

              make_operation_of(bank_account, transactions) if bank_account && transactions.present?
            else
              log_message += "[BudgeaTransactionFetcher][#{@user.code}] - No retriever found, for connection id: #{account['id_connection']}\n"
            end
          end
        else
          log_message += "[BudgeaTransactionFetcher][#{@user.code}] - No bank accounts found! OR Unauthorized => #{@accounts.to_s}"
          LogService.info('budgea_fetch_processing', log_message)
          return log_message
        end
      else
        log_message += "[BudgeaTransactionFetcher][#{@user.code}] - Parameters invalid!"
        LogService.info('budgea_fetch_processing', log_message)
        return log_message
      end
    else
      log_message += "[BudgeaTransactionFetcher][#{@user.try(:code)}] - Budgea client invalid! - no budgea account configured for the user"
      LogService.info('budgea_fetch_processing', log_message)
      return log_message
    end
    log_message += "[BudgeaTransactionFetcher][#{@user.try(:code)}] - New operations: #{@new_operations_count} / Deleted operations: #{@deleted_operations_count} / Total operations fetched: #{@operations_fetched_count}"
    LogService.info('budgea_fetch_processing', log_message)
    return log_message
  end

  def parse_of(json_content)
    connections = json_content[:content]['connections']

    connections.each do |connection|
      next if connection['id'].in?(@retrieved_data.processed_connection_ids)

      @is_connection_ok = true
      @connection_id    = connection['id']

      connection.merge!("source"=>"retrieve_data")
      process connection if retriever

      if @is_connection_ok
        @retrieved_data.processed_connection_ids << connection['id']
        @retrieved_data.save
      end

      break if @run_until && @run_until < Time.now
    end
  end

  def process(connection)
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

    notify connection
    retriever.reload

    retriever.update(sync_at: Time.now)

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
      LogService.info('retrieved_data', "[#{@user.code}][RetrievedData:#{@retrieved_data.id}] Error: #{@retrieved_data.error_message}")
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
      bank_account.original_currency = account['currency']
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
          file_state = RetrievedDocument.process_file(retriever.id, document, 0)

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

  def notify(connection)
    retriever.update_state_with connection

    if retriever.reload.budgea_connection_successful?
      RetrieverNotification.new(retriever).notify_new_documents(@new_documents_count) if @new_documents_count > 0
      RetrieverNotification.new(retriever).notify_new_operations(@new_operations_count) if @new_operations_count > 0
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
        else
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

  def set_transaction_value(bank_account, transaction)
    if (transaction['value'].nil? && bank_account.bank_name.downcase == 'paypal rest api')
      transaction['gross_value'] + transaction['commission'] if (transaction['gross_value'].present? && transaction['commission'].present?)
    else
      transaction['value']
    end
  end

  def lock_operation?(bank_account, operation)
    (bank_account.start_date.present? && operation.date < bank_account.start_date) ||
      operation.date < Date.parse('2017-01-01') ||
      operation.is_coming ||
      is_operation_old?(bank_account, operation)
  end

  def is_operation_old?(bank_account, operation)
    bank_account.lock_old_operation &&
      bank_account.created_at < 1.month.ago &&
      operation.date < bank_account.permitted_late_days.days.ago.to_date
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

    @retriever = @user.retrievers.where(budgea_id: @connection_id).order(created_at: :asc).first
  end

  def get_bank_account_of(account)
    @user.bank_accounts.where('api_id = ? OR (name = ? AND number = ?)', account['id'], account['name'], account['number']).first
  end
end
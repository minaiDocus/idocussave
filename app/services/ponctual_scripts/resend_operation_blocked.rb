class PonctualScripts::ResendOperationBlocked < PonctualScripts::PonctualScript
  def self.execute(piece_name)
    new({piece_name: piece_name}).run
  end

  private

  def execute
    api_ids = Operation.where(api_id: @options[:piece_name]).collect(&:api_id).uniq
    @result    = { created_operation: [], created_operation_count: 0, rejected_operation: [], rejected_operation_count: 0 }

    logger_infos "[ResendOperationBlocked] - total piece need to resend: #{api_ids.size}"

    api_ids.each do |api_id|
      logger_infos "[ResendOperationBlocked] - with api_id: #{api_id} - Start"

      file_p = "/nfs/staffing_internal/livraison/pre_assigning/#{api_id}.json"
      if File.exist?(file_p)
        content  = File.read(file_p)
        assign_data(JSON.parse(content))
      else
        logger_infos "[ResendOperationBlocked] - #{api_id} - doesn't exist"
      end

      logger_infos "[ResendOperationBlocked] - with api_id: #{api_id} - Finished"
    end

    store_operation_result

    mail_infos = {
      subject: "[PonctualScripts::ResendOperationBlocked] resend operation blocked",
      name: "PonctualScripts::ResendOperationBlocked",
      error_group: "[PonctualScripts] Resend Operation Blocked",
      erreur_type: "PonctualScripts to resend operation blocked ",
      date_erreur: Time.now.strftime('%Y-%m-%d %H:%M:%S'),
      more_information: {
        rejected_operation_count: @result[:rejected_operation_count],
        created_operation_count: @result[:created_operation_count]
      }
    }

    begin
      ErrorScriptMailer.error_notification(mail_infos, { attachements: [{name: 'operations_results.json', file: File.read(file_path)}] } ).deliver
    rescue
      ErrorScriptMailer.error_notification(mail_infos).deliver
    end
  end

  def assign_data(operations)
    operations.each do |operation|
      operation = operation.with_indifferent_access

      @bank_account = BankAccount.find(operation[:bank_account_id])

      logger_infos "[ResendOperationBlocked] - #{operation[:label]} sending"
      @operation = Operation.new(operation)
      @operation.api_name = 'capidocus'

      perform(operation)

      @operation.reload

      if @operation.api_name == 'capidocus' && @operation.api_id
        piece = Pack::Piece.find_by_name(@operation.api_id.gsub("_", ' '))

        piece.processed_pre_assignment if piece && !piece.pre_assignment_processed?
      end

      @operation.user.billing_histories.find_or_create(@operation.date.strftime('%Y%m').to_i, @operation.user.subscription.current_period)
    end
  end

  def perform(operation)
    set_operation_currency
    set_operation_administrative_infos

    append_credit_card_tag if @bank_account.type_name == 'card'

    is_duplicate = is_duplicate?
    if is_duplicate || @operation.to_lock?
      @operation.is_locked = true

      if is_duplicate
        @operation.comment = 'Locked for duplication'
        logger_infos "[ResendOperationBlocked] - #{operation[:label]} already sent"
        @result[:rejected_operation] << operation
        @result[:rejected_operation_count] += 1
      end
    end

    if !is_duplicate
      @result[:created_operation] << operation
      @result[:created_operation_count] += 1

      logger_infos "[ResendOperationBlocked] - #{operation[:label]} finished"
    end

    @operation.save

    @operation
  end

  def append_credit_card_tag
    @operation.label = '[CB]' + @operation.label
  end

  def set_operation_currency
    case @operation.temp_currency
    when 'EUR'
      @operation.currency = { id: 'EUR', symbol: '€', prefix: false, crypto: false, precision: 2, marketcap: nil, datetime: nil, name: 'Euro'}
    when 'USD'
      @operation.currency = { id: 'USD', symbol: '$', prefix: true, crypto: false, precision: 2, marketcap: nil, datetime: nil, name: 'US Dollar'}
    when 'GBP'
      @operation.currency = { id: 'GBP', symbol: '£', prefix: false, crypto: false, precision: 2, marketcap: nil, datetime: nil, name: 'British Pound Sterling'}
    when 'CHF'
      @operation.currency = { id: 'CHF', symbol: 'CHF', prefix: false, crypto: false, precision: 2, marketcap: nil, datetime: nil, name: 'Swiss Franc'}
    when 'ZAR'
      @operation.currency = { id: 'ZAR', symbol: 'R', prefix: false, crypto: false, precision: 2, marketcap: nil, datetime: nil, name: 'South African Rand'}
    end
  end

  def set_operation_administrative_infos
    @operation.user = @bank_account.user
    @operation.organization = @operation.user.organization
  end

  def store_operation_result
    File.write(file_path, JSON.dump(@result))
  end

  def is_duplicate?
    @bank_account.operations.where(amount: @operation.amount, date: @operation.date).count > 0
  end

  def file_path
    File.join(ponctual_dir, 'operations_results.json')
  end

  def ponctual_dir
    dir = "#{Rails.root}/spec/support/files/ponctual_scripts/operations"
    FileUtils.makedirs(dir)
    FileUtils.chmod(0777, dir)
    dir
  end
end
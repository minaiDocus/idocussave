class PonctualScripts::ResendOperationBlocked < PonctualScripts::PonctualScript
  def self.execute
    new().run
  end

  private

  def execute
    operations = Operation.where('created_at BETWEEN "2021-02-19 00:00:00" AND "2021-02-23 12:25:00" AND api_name = "capidocus"').collect(&:api_id)
    @result    = { created_operation: [], created_operation_count: 0, rejected_operation: [], rejected_operation_count: 0 }

    logger_infos "[ResendOperationBlocked] - total operation need to resend: #{operations.size}"

    operations.each do |api_id|
      logger_infos "[ResendOperationBlocked] - with api_id: #{api_id} - Start"

      content  = File.read("/nfs/staffing_internal/livraison/pre_assigning/#{api_id}.json")
      assign_data(JSON.parse(content))

      logger_infos "[ResendOperationBlocked] - with api_id: #{api_id} - Finished"
    end

    store_operation_result

    mail_infos = {
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
      ErrorScriptMailer.error_notification(mail_infos, { attachements: [{name: 'result.json', file: File.read(file_path)}] } ).deliver
    rescue
      ErrorScriptMailer.error_notification(mail_infos).deliver
    end
  end

  def assign_data(operations)
    operations.each do |operation|
      @bank_account = BankAccount.find(operation[:bank_account_id])

      if @bank_account.operations.where(amount: operation[:amount], date: operation[:date], api_name: 'capidocus').size > 0
        logger_infos "[ResendOperationBlocked] - #{operation[:label]} already sent"
        @result[:rejected_operation] << operation
        @result[:rejected_operation_count] += 1
        next
      else
        logger_infos "[ResendOperationBlocked] - #{operation[:label]} sending"
        @operation = Operation.new(operation)
        @operation.api_name = 'capidocus'

        perform

        @operation.reload

        if @operation.api_name == 'capidocus' && @operation.api_id
          piece = Pack::Piece.find_by_name(@operation.api_id.gsub("_", ' '))

          piece.processed_pre_assignment if piece && !piece.pre_assignment_processed?
        end

        @operation.user.billing_histories.find_or_create(@operation.date.strftime('%Y%m').to_i, @operation.user.subscription.current_period)

        @result[:created_operation] << operation
        @result[:created_operation_count] += 1

        logger_infos "[ResendOperationBlocked] - #{operation[:label]} finished"
      end
    end
  end

  def perform
    set_operation_currency
    set_operation_administrative_infos

    append_credit_card_tag if @bank_account.type_name == 'card'

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
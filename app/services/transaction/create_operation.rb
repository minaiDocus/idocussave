class Transaction::CreateOperation
  def initialize(operation)
    @operation = operation
    @bank_account = BankAccount.find(@operation.bank_account_id)
  end

  def self.perform(operations)
    result = { created_operation: 0, rejected_operation: 0 }

    operations.each do |o|
      operation = Operation.new(o)
      operation.api_name ||= 'capidocus'

      @api_name = operation.api_name

      if new(operation).perform.persisted?
        result[:created_operation] += 1
      else
        result[:rejected_operation] += 1
      end
    end

    if @api_name == 'capidocus' && operations[0]['api_id']
      piece = Pack::Piece.find_by_name(operations[0]['api_id'].gsub("_", ' '))

      if piece
        piece.update(is_awaiting_pre_assignment: false)
        piece.processed_pre_assignment
      end
    end

    result
  end

  def perform
    if check_duplicates
      append_credit_card_tag if @bank_account.type_name == 'card'

      set_operation_currency
      set_operation_administrative_infos

      @operation.save
    else
      @operation.errors.add(:amount, :invalid, message: 'La transaction semble déjà présente en base')
    end

    @operation
  end

  private

  def check_duplicates
    duplicates = @bank_account.operations.where(amount: @operation.amount, date: @operation.date)

    duplicates.count > 0 ? false : true
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
end
class Transaction::CreateOperation
  def initialize(operation)
    @operation    = operation
    @bank_account = BankAccount.where(id: @operation.bank_account_id.to_i).first
  end

  def self.perform(operations)
    result = { created_operation: 0, rejected_operation: 0 }

    operations.each do |o|
      operation = Operation.new(o)
      operation.api_name = 'capidocus'

      new_operation = new(operation).perform

      return false if not new_operation

      if new_operation.is_locked
        result[:rejected_operation] += 1
      else
        result[:created_operation] += 1
      end

      if operation.api_name == 'capidocus' && operation.api_id
        piece = Pack::Piece.find_by_name(operation.api_id.gsub("_", ' '))

        piece.processed_pre_assignment if piece && !piece.pre_assignment_processed?
      end
    end

    result
  end

  def perform
    return nil if not @bank_account && @bank_account.try(:user).try(:options).try(:is_retriever_authorized)

    set_operation_currency
    set_operation_administrative_infos

    append_credit_card_tag if @bank_account.type_name == 'card'

    is_duplicate = is_duplicate?
    if is_duplicate || @operation.to_lock?
      @operation.is_locked = true
      @operation.comment = 'Locked for duplication' if is_duplicate
    end

    @operation.save

    @operation
  end

  private

  def is_duplicate?
    @bank_account.operations.where.not(api_name: 'capidocus').where(amount: @operation.amount, date: @operation.date).count > 0
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
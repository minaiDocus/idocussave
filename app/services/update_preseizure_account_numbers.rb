# -*- encoding : UTF-8 -*-
class UpdatePreseizureAccountNumbers
  class << self
    def async_execute(bank_account_id, changes)
      bank_account = BankAccount.find bank_account_id
      new(bank_account, changes).execute
    end
    handle_asynchronously :async_execute, queue: 'update_preseizure_account_number', priority: 0
  end

  def initialize(bank_account, changes)
    @bank_account = bank_account
    @changes = changes
  end

  def execute
    if @changes['journal'].nil?
      update_account(*@changes['accounting_number']) if @changes['accounting_number']
      update_account(*@changes['temporary_account']) if @changes['temporary_account']
    end
  end

private

  def operation_ids
    @operation_ids ||= @bank_account.operations.distinct(:_id)
  end

  def preseizure_ids
    @preseizure_ids ||= Pack::Report::Preseizure.where(:operation_id.in => operation_ids, is_delivered: false).distinct(:_id)
  end

  def update_account(old_number, new_number)
    ::Pack::Report::Preseizure::Account.all.where(
      :preseizure_id.in => preseizure_ids,
      number: old_number).
      update_all(number: new_number)
  end
end

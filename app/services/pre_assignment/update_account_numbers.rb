# -*- encoding : UTF-8 -*-
# Update account numbers for updated bank_account
class PreAssignment::UpdateAccountNumbers
  def self.execute(bank_account_id, changes)
    bank_account = BankAccount.find(bank_account_id)

    new(bank_account, changes).execute
  end


  def initialize(bank_account, changes)
    @changes         = changes
    @bank_account    = bank_account
  end


  def execute
    if @changes['journal'].nil?
      update_account(*@changes['temporary_account']) if @changes['temporary_account']
      update_account(*@changes['accounting_number']) if @changes['accounting_number']
    end
  end

  private


  def operation_ids
    @operation_ids ||= @bank_account.operations.pluck(:id)
  end


  def preseizure_ids
    # TO DO: check is_delivered_to
    @preseizure_ids ||= Pack::Report::Preseizure.unscoped.where(operation_id: operation_ids, is_delivered_to: nil).pluck(:id)
  end


  def update_account(old_number, new_number)
    Pack::Report::Preseizure::Account.all.where(preseizure_id: preseizure_ids, number: old_number).update_all(number: new_number)
  end
end

# -*- encoding : UTF-8 -*-
class OperationService
  def self.fetch(object, update=false)
    if object.class.to_s.in?(%w(User FiduceoRetriever))
      bank_accounts = object.bank_accounts
    else
      bank_accounts = Array(object)
    end
    bank_accounts.each do |bank_account|
      operations = FiduceoOperation.new(bank_account.user.fiduceo_id, account_id: bank_account.fiduceo_id).operations || []
      operations.each do |temp_operation|
        operation = Operation.where(fiduceo_id: temp_operation.id).first
        if update && operation
          operation.bank_account = bank_account
          assign_attributes(operation, temp_operation)
          operation.save
        elsif !update && !operation
          operation = Operation.new
          operation.user         = bank_account.user
          operation.bank_account = bank_account
          operation.fiduceo_id   = temp_operation.id
          assign_attributes(operation, temp_operation)
          operation.save
        end
      end
    end
  end

private

  def self.assign_attributes(operation, temp_operation)
    operation.date             = temp_operation.date_op
    operation.value_date       = temp_operation.date_val
    operation.transaction_date = temp_operation.date_transac
    operation.label            = temp_operation.label
    operation.amount           = temp_operation.amount
    operation.comment          = temp_operation.comment
    operation.supplier_found   = temp_operation.supplier_found
    operation.type_id          = temp_operation.type_id
    operation.category_id      = temp_operation.category_id
    operation.category         = temp_operation.category
  end
end

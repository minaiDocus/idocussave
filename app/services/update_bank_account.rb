# Updates one or many bank accounts
class UpdateBankAccount
  def self.execute(bank_account, params)
    bank_account.assign_attributes(params)

    changes = @bank_account.changes.dup

    if @bank_account.save
      @bank_account.operations.where(is_locked: true).where('date >= ?' , @bank_account.start_date).update_all(is_locked: false)

      UpdatePreseizureAccountNumbers.delay.execute(@bank_account.id, changes)

      true
    else
      false
    end
  end


  def self.execute_multiple(bank_accounts, params)
    if params.is_a?(Hash) && params.any?
      params.each do |fiduceo_id, value|
        bank_account = bank_accounts.select { |e| e.fiduceo_id == fiduceo_id }.first

        next unless bank_account

        is_selected = value == '1'

        if !bank_account.persisted? && is_selected
          bank_account.save

          OperationService.update_bank_account(bank_account)
        elsif bank_account.persisted? && !is_selected
          bank_account.destroy
        end
      end

      true
    end
  end
end

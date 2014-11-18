class AccountBookTypeObserver < Mongoid::Observer
  def before_save(journal)
    unless journal.is_pre_assignment_processable?
      journal.account_number         = ''
      journal.default_account_number = ''
      journal.charge_account         = ''
      journal.default_charge_account = ''
      journal.vat_account            = ''
      journal.anomaly_account        = ''
    end
  end
end

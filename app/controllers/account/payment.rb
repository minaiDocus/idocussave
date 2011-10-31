class Account::PaymentsController < Account::AccountController
  skip_before_filter :find_last_composition

  skip_before_filter :verify_authenticity_token, :only => [:mode]
public
  def mode
    if params[:use_debit_mandate] && current_user.debit_mandate != nil
      current_user.use_debit_mandate = true if current_user.debit_mandate.transactionStatus == "success"
    else
      current_user.use_debit_mandate = false
    end
  end
end

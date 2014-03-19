# -*- encoding : UTF-8 -*-
class Account::DebitMandatesController < Account::AccountController
  skip_before_filter :find_last_composition

public
  def show
    @debit_mandate = DebitMandate.where(:user_id => @user.id).first
  end
  
  def new
    @debit_mandate = DebitMandate.new
  end
  
  def return
    if @user.debit_mandate.transactionStatus == "success"
      flash[:notice] = "Vos information de prélévement bancaire on bien été pris en compte par nos services."
      render :action => "show"
    else
      flash[:notice] = "Une erreur est survenu lors du traitement. Veuillez réessayer à nouveau."
      render :action => "new"
    end
  end
end

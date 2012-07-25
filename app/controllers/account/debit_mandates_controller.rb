# -*- encoding : UTF-8 -*-
class Account::DebitMandatesController < Account::AccountController
  skip_before_filter :find_last_composition

public
  def show
    @debit_mandate = DebitMandate.where(:user_id => current_user.id).first
  end
  
  def new
    @user = current_user
    @debit_mandate = DebitMandate.new
  end
  
  def return
    if current_user.debit_mandate.transactionStatus == "success"
      flash[:notice] = "Vos information de pr�l�vement bancaire on bien �t� pris en compte par nos services."
      render :action => "show"
    else
      flash[:notice] = "Une erreur est survenu lors du traitement. Veuillez r�essayer � nouveau."
      render :action => "new"
    end
  end
end

# -*- encoding : UTF-8 -*-
class Account::DebitMandatesController < Account::AccountController
  # GET /account/debit_mandate
  def show
    @debit_mandate = DebitMandate.where(user_id: @user.id).first
  end


  # GET /account/debit_mandate/new

  def new
    @debit_mandate = DebitMandate.new
  end


  # GET /account/debit_mandate/return
  def return
    if @user.debit_mandate.transactionStatus == 'success'
      flash[:notice] = "Vos information de prélévement bancaire on bien été pris en compte par nos services."
      render :show
    else
      flash[:notice] = "Une erreur est survenu lors du traitement. Veuillez réessayer à nouveau."
      render :edit
    end
  end
end

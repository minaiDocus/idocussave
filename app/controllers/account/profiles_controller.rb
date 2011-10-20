class Account::ProfilesController < Account::AccountController
  skip_before_filter :find_last_composition
  
  helper :paiement_cic

public

  def show
    @user = current_user
    if params[:amount]
      amount = params[:amount].to_f * 100
      ok = Credit.where(:state => "unpaid", :user_id => current_user.id).last.amount != amount rescue true
    	if ok
    	  @credit = Credit.create!(:amount => amount, :user => current_user)
      else
        @credit = Credit.last
      end
      values = {
        :business => 'lailol_1312465379_biz@directmada.com',
        :cmd => '_cart',
        :upload => 1,
        :notify_url => "#{notify_account_paypal_url}?order_id=#{@credit.number}",
        :return => "#{success_account_paypal_url}?order_id=#{@credit.number}",
        :cancel_return => "#{cancel_account_paypal_url}?order_id=#{@credit.number}",
        :invoice => @credit.number,
        :amount_1 => amount/100,
        :currency_code => 'EUR',
        :item_name_1 => "Crédit",
        :item_number_1 => 1,
        :quantity_1 => 1
      }
      @link_to_paypal = "https://www.sandbox.paypal.com/cgi-bin/webscr?"+ values.to_query
    end
  end

  def update
    @user = current_user   
    if @user.valid_password?(params[:user][:current_password])
      if @user.update_attributes(params[:user])
        flash[:notice] = "Votre mot de passe a été mis à jour avec succès"
      else
        flash[:alert] = "Une erreur est survenue lors de la mise à jour de votre mot de passe"
      end
    else
      flash[:alert] = "Votre ancien mot de passe n'a pas été saisi correctement"
    end

    redirect_to account_profile_path(@user)
  end
end

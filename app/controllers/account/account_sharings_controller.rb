# frozen_string_literal: true

class Account::AccountSharingsController < Account::AccountController
  def new
    @contact = User.new(company: @user.company)
  end

  def create
    @contact, @account_sharing = AccountSharing::ShareMyAccount.new(@user, account_sharing_params, current_user).execute
    if @account_sharing.persisted?
      flash[:success] = 'Votre compte a été partagé avec succès.'
      redirect_to account_profile_path(panel: :account_sharing)
    elsif Array(@account_sharing.errors[:account] || @account_sharing.errors[:collaborator]).include?('est déjà pris.')
      flash[:notice] = 'Ce contact a déjà accès à votre compte.'
      redirect_to account_profile_path(panel: :account_sharing)
    elsif @contact.errors[:email].include?('est déjà pris.') || @account_sharing.errors[:collaborator_id].include?("n'est pas valide")
      flash[:error] = "Vous ne pouvez pas partager votre compte avec le contact : #{@contact.email}."
      redirect_to account_profile_path(panel: :account_sharing)
    else
      render :new
    end
  end

  def destroy
    @account_sharing = AccountSharing.unscoped.where(id: params[:id]).where('account_id = :id OR collaborator_id = :id', id: @user.id).first!
    if AccountSharing::Destroy.new(@account_sharing, @user).execute
      flash[:success] = 'Le partage a été annulé avec succès.'
    else
      flash[:error] = 'Impossible de supprimer le partage.'
    end
    redirect_to account_profile_path(panel: :account_sharing)
  end

  def new_request
    @account_sharing_request = AccountSharingRequest.new
  end

  def create_request
    @account_sharing_request = AccountSharingRequest.new(account_sharing_request_params)
    @account_sharing_request.user = @user
    if @account_sharing_request.save
      flash[:success] = 'Demande envoyé avec succès.'
      redirect_to account_profile_path(panel: :account_sharing)
    else
      render :new_request
    end
  end

  private

  def account_sharing_params
    params.require(:user).permit(:email, :company, :first_name, :last_name)
  end

  def account_sharing_request_params
    params.require(:account_sharing_request).permit(:code_or_email)
  end
end

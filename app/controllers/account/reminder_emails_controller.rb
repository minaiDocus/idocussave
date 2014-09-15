# -*- encoding : UTF-8 -*-
class Account::ReminderEmailsController < Account::OrganizationController
  before_filter :verify_rights
  before_filter :load_reminder_email, except: %w(new create)

  def show
    render layout: nil
  end

  def new
    @reminder_email = ReminderEmail.new
  end

  def create
    @reminder_email = ReminderEmail.new reminder_email_params
    @reminder_email.organization = @organization
    if @reminder_email.save
      flash[:success] = 'Créé avec succès.'
      redirect_to account_organization_path(@organization, tab: 'reminder_emails')
    else
      render 'new'
    end
  end

  def edit
  end

  def update
    if @reminder_email.update_attributes(reminder_email_params)
      flash[:success] = 'Modifié avec succès.'
      redirect_to account_organization_path(@organization, tab: 'reminder_emails')
    else
      render 'edit'
    end
  end

  def destroy
    @reminder_email.destroy
    flash[:success] = 'Supprimé avec succès.'
    redirect_to account_organization_path(@organization, tab: 'reminder_emails')
  end

  def deliver
    result = @reminder_email.deliver
    if result.is_a? Boolean and result == true
      flash[:success] = 'Envoyé avec succès.'
    elsif result.is_a? Array and result.empty?
      flash[:notice] = 'Les mails ont déjà été envoyés.'
    else
      flash[:error] = 'Une erreur est survenu lors de la livraison.'
    end
    redirect_to account_organization_path(@organization, tab: 'reminder_emails')
  end

private

  def verify_rights
    unless @user.is_admin
      flash[:error] = t('authorization.unessessary_rights')
      redirect_to account_organization_path(@organization)
    end
  end

  def load_reminder_email
    @reminder_email = @organization.reminder_emails.find params[:id]
  end

  def reminder_email_params
    params.require(:reminder_email).permit(
      :name,
      :delivery_day,
      :period,
      :subject,
      :content
    )
  end
end

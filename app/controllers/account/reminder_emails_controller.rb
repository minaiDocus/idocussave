# frozen_string_literal: true

class Account::ReminderEmailsController < Account::OrganizationController
  before_action :verify_rights
  before_action :load_reminder_email, except: %w[new create]

  # GET /account/organizations/:organization_id/reminder_emails/:id
  def show
    render layout: nil
  end

  # GET /account/organizations/:organization_id/reminder_emails/new
  def new
    @reminder_email = ReminderEmail.new

    if params[:template].present?
      template = @organization.reminder_emails.find params[:template]

      @reminder_email.name    = template.name
      @reminder_email.period  = template.period
      @reminder_email.subject = template.subject
      @reminder_email.content = template.content
      @reminder_email.delivery_day = template.delivery_day
    end
  end

  # POST # GET /account/organizations/:organization_id/reminder_emails
  def create
    @reminder_email = ReminderEmail.new reminder_email_params

    @reminder_email.organization = @organization

    if @reminder_email.save
      flash[:success] = 'Créé avec succès.'

      redirect_to account_organization_path(@organization, tab: 'reminder_emails')
    else
      render :new
    end
  end

  # GET /account/organizations/:organization_id/reminder_emails/:id/edit
  def edit; end

  # PUT /account/organizations/:organization_id/reminder_emails/:id
  def update
    if @reminder_email.update(reminder_email_params)
      flash[:success] = 'Modifié avec succès.'

      redirect_to account_organization_path(@organization, tab: 'reminder_emails')
    else
      render 'edit'
    end
  end

  # DELETE /account/organizations/:organization_id/reminder_emails/:id
  def destroy
    @reminder_email.destroy

    flash[:success] = 'Supprimé avec succès.'

    redirect_to account_organization_path(@organization, tab: 'reminder_emails')
  end

  # POST /account/organizations/:organization_id/reminder_emails/:id/deliver
  def deliver
    result = @reminder_email.deliver

    if result.is_a?(TrueClass) || result.is_a?(FalseClass) && result == true
      flash[:success] = 'Envoyé avec succès.'
    elsif result.is_a?(Array) && result.empty?
      flash[:notice] = 'Les mails ont déjà été envoyés.'
    else
      flash[:error] = 'Une erreur est survenu lors de la livraison.'
    end

    redirect_to account_organization_path(@organization, tab: 'reminder_emails')
  end

  private

  def verify_rights
    unless @user.is_admin || (@user.is_prescriber && @user.organization == @organization)
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

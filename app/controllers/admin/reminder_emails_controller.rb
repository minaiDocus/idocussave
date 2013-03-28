# -*- encoding : UTF-8 -*-
class Admin::ReminderEmailsController < Admin::AdminController
  before_filter :load_organization

  layout :nil_layout

  public

  def index
    @reminder_emails = @organization.reminder_emails
  end

  def edit_multiple
  end

  def update_multiple
    respond_to do |format|
      if @organization.update_attributes(params[:organization])
        format.json{ render json: {}, status: :ok }
        format.html{ redirect_to admin_organization_path(@organization) }
      else
        format.json{ render json: @organization.errors.to_json, status: :unprocessable_entity }
        format.html{ render action: 'edit_multiple' }
      end
    end
  end

  def preview
    @reminder_email = @organization.reminder_emails.find params[:id]
  end

  def deliver
    @reminder_email = @organization.reminder_emails.find params[:id]
    result = @reminder_email.deliver
    if result.is_a? Boolean and result == true
      flash[:notice] = 'Délivré avec succès.'
    elsif result.is_a? Array and result.empty?
      flash[:notice] = 'Les mails ont déjà été envoyé.'
    else
      flash[:error] = 'Une erreur est survenu lors de la livraison.'
    end
    redirect_to admin_organization_path(@organization)
  end
end
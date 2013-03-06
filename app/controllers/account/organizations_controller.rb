# -*- encoding : UTF-8 -*-
class Account::OrganizationsController < Account::AccountController
  layout 'organization'

  before_filter :verify_management_access
  before_filter :load_user
  before_filter :load_organization
  before_filter :verify_rights, only: %w(edit update)

  def show
    if @organization
      @members = @organization.customers.page(params[:page]).per(params[:per])
      @periods = ::Scan::Period.where(:user_id.in => @organization.customers.map(&:_id), :start_at.lt => Time.now, :end_at.gt => Time.now).entries
    end
  end

  def edit
  end

  def update
    if @organization
      if @organization.update_attributes(organization_params)
        flash[:success] = "Modifié avec succès."
        redirect_to account_organization_path
      else
        render 'edit'
      end
    end
  end

private

  def verify_rights
    unless @organization && @organization.authorized?(@user)
      flash[:error] = "Vous n'êtes pas autorisé à effectuer cette action."
      redirect_to account_organization_path
    end
  end

  def organization_params
    params.require(:organization).permit(:name,
                                         :description,
                                         :is_add_authorized,
                                         :is_remove_authorized,
                                         :is_create_authorized,
                                         :is_edit_authorized,
                                         :is_destroy_authorized,
                                         :centralized_customer_tokens,
                                         :addresses_attributes)
  end

end
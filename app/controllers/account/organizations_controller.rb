# -*- encoding : UTF-8 -*-
class Account::OrganizationsController < Account::OrganizationController
  skip_before_filter :verify_rights, only: 'show'

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
        flash[:success] = 'Modifié avec succès.'
        redirect_to account_organization_path
      else
        render 'edit'
      end
    end
  end

private

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
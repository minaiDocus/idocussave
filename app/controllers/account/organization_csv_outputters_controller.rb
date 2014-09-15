# -*- encoding : UTF-8 -*-
class Account::OrganizationCsvOutputtersController < Account::OrganizationController
  before_filter :verify_rights
  before_filter :load_csv_outputter, except: :select_propagation_options

  def edit
  end

  def update
    if @csv_outputter.update_attributes(csv_outputter_params)
      flash[:success] = 'Modifié avec succès.'
      redirect_to account_organization_path(@organization, tab: 'csv_outputter')
    else
      render 'edit'
    end
  end

  def select_propagation_options
    @customers = @organization.customers.active.asc(:code)
  end

  def propagate
    organization_customer_ids = @organization.customers.active.map(&:id).map(&:to_s)
    customer_ids = (params[:customer_ids].presence || []).select do |customer_id|
      organization_customer_ids.include? customer_id
    end
    @csv_outputter.copy_to_users(customer_ids)
    flash[:success] = 'Propagé avec succès.'
    redirect_to account_organization_path(@organization, tab: 'csv_outputter')
  end

private

  def verify_rights
    unless @user.is_admin
      flash[:error] = t('authorization.unessessary_rights')
      redirect_to account_organization_path(@organization)
    end
  end

  def load_csv_outputter
    @csv_outputter = @organization.csv_outputter!
  end

  def csv_outputter_params
    params.require(:csv_outputter).permit(:directive, :comma_as_number_separator)
  end
end

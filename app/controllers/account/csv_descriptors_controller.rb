# frozen_string_literal: true

class Account::CsvDescriptorsController < Account::OrganizationController
  before_action :verify_rights
  before_action :load_customer
  before_action :redirect_to_current_step
  before_action :load_csv_descriptor

  # GET /account/organizations/:organization_id/csv_descriptor/edit
  def edit
    if params[:template].present?
      template = @organization.try(:csv_descriptor)

      @csv_descriptor.comma_as_number_separator = template.comma_as_number_separator

      @csv_descriptor.directive = template.directive
    end
  end

  # PUT account/organizations/:organization_id/customers/:customer_id/csv_descriptor
  def update
    if @csv_descriptor.update(csv_descriptor_params)
      if @customer.configured?
        flash[:success] = 'Modifié avec succès.'

        redirect_to account_organization_customer_path(@organization, @customer, tab: 'csv_descriptor')
      else
        next_configuration_step
      end
    else
      render 'edit'
    end
  end

  # PUT /account/organizations/:organization_id/customers/:customer_id/csv_descriptor/activate
  def activate
    @customer.try(:csv_descriptor).update_attribute(:use_own_csv_descriptor_format, true)

    redirect_to edit_account_organization_customer_csv_descriptor_path(@organization, @customer, template: true)
  end

  # PUT  /account/organizations/:organization_id/customers/:customer_id/csv_descriptor/deactivate
  def deactivate
    @customer.try(:csv_descriptor).update_attribute(:use_own_csv_descriptor_format, false)

    flash[:success] = 'Modifié avec succès.'

    redirect_to account_organization_customer_path(@organization, @customer, tab: 'csv_descriptor')
  end

  private

  def verify_rights
    unless @user.is_admin || (@user.is_prescriber && @user.organization == @organization) || @organization.try(:csv_descriptor).try(:used?)
      flash[:error] = t('authorization.unessessary_rights')
      redirect_to account_organization_path(@organization)
    end
  end

  def load_customer
    @customer = customers.find params[:customer_id]
  end

  def load_csv_descriptor
    @csv_descriptor = @customer.csv_descriptor!
  end

  def csv_descriptor_params
    params.require(:software_csv_descriptor).permit(:directive, :comma_as_number_separator)
  end
end

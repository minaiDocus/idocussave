# -*- encoding : UTF-8 -*-
class Account::CsvDescriptorsController < Account::OrganizationController
  before_filter :verify_rights
  before_filter :load_customer
  before_filter :load_csv_descriptor

  def edit
    if params[:template].present?
      template = @organization.csv_descriptor
      @csv_descriptor.comma_as_number_separator = template.comma_as_number_separator
      @csv_descriptor.directive = template.directive
    end
  end

  def update
    if @csv_descriptor.update(csv_descriptor_params)
      flash[:success] = 'Modifié avec succès.'
      redirect_to account_organization_customer_path(@organization, @customer, tab: 'csv_descriptor')
    else
      render 'edit'
    end
  end

  def activate
    @customer.options.update_attribute(:is_own_csv_descriptor_used, true)
    redirect_to edit_account_organization_customer_csv_descriptor_path(@organization, @customer, template: true)
  end

  def deactivate
    @customer.options.update_attribute(:is_own_csv_descriptor_used, false)
    flash[:success] = 'Modifié avec succès.'
    redirect_to account_organization_customer_path(@organization, @customer, tab: 'csv_descriptor')
  end

private

  def verify_rights
    unless @user.is_admin || (@user.is_prescriber && @user.organization == @organization) || @organization.is_csv_descriptor_used
      flash[:error] = t('authorization.unessessary_rights')
      redirect_to account_organization_path(@organization)
    end
  end

  def load_customer
    @customer = customers.find_by_slug! params[:customer_id]
    raise Mongoid::Errors::DocumentNotFound.new(User, slug: params[:customer_id]) unless @customer
  end

  def load_csv_descriptor
    @csv_descriptor = @customer.csv_descriptor!
  end

  def csv_descriptor_params
    params.require(:csv_descriptor).permit(:directive, :comma_as_number_separator)
  end
end

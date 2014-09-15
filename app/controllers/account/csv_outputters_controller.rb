# -*- encoding : UTF-8 -*-
class Account::CsvOutputtersController < Account::OrganizationController
  before_filter :verify_rights
  before_filter :load_customer
  before_filter :load_csv_outputter

  def edit
  end

  def update
    if @csv_outputter.update_attributes(csv_outputter_params)
      flash[:success] = 'Modifié avec succès.'
      redirect_to account_organization_customer_path(@organization, @customer, tab: 'csv_outputter')
    else
      render 'edit'
    end
  end

private

  def verify_rights
    unless current_user.is_admin
      flash[:error] = t('authorization.unessessary_rights')
      redirect_to account_organization_path(@organization)
    end
  end

  def load_customer
    @customer = customers.find_by_slug params[:customer_id]
  end

  def load_csv_outputter
    @csv_outputter = @customer.csv_outputter!
  end

  def csv_outputter_params
    params.require(:csv_outputter).permit(:directive, :comma_as_number_separator)
  end
end

# -*- encoding : UTF-8 -*-
class Account::OrganizationCsvOutputtersController < Account::OrganizationController
  before_filter :verify_rights
  before_filter :load_csv_outputter, except: :select_propagation_options

  def edit
  end

  def update
    if @csv_outputter.update(csv_outputter_params)
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
    registered_ids = @organization.customers.active.map(&:id).map(&:to_s)
    valid_ids = (params[:customer_ids].presence || []).select do |customer_id|
      registered_ids.include? customer_id
    end
    CsvOutputter.where(:user_id.in => valid_ids).update_all(
      comma_as_number_separator: @csv_outputter.comma_as_number_separator,
      directive:                 @csv_outputter.directive,
      updated_at:                Time.now
    )
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

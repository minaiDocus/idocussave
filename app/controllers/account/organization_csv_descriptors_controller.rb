# -*- encoding : UTF-8 -*-
class Account::OrganizationCsvDescriptorsController < Account::OrganizationController
  before_filter :verify_rights
  before_filter :load_csv_descriptor

  def edit
  end

  def update
    if @csv_descriptor.update(csv_descriptor_params)
      flash[:success] = 'Modifié avec succès.'
      redirect_to account_organization_path(@organization, tab: 'csv_descriptor')
    else
      render 'edit'
    end
  end

private

  def verify_rights
    unless @user.is_admin
      flash[:error] = t('authorization.unessessary_rights')
      redirect_to account_organization_path(@organization)
    end
  end

  def load_csv_descriptor
    @csv_descriptor = @organization.csv_descriptor!
  end

  def csv_descriptor_params
    params.require(:csv_descriptor).permit(:directive, :comma_as_number_separator)
  end
end
# frozen_string_literal: true

class Account::OrganizationCsvDescriptorsController < Account::OrganizationController
  before_action :verify_rights
  before_action :load_csv_descriptor

  # GET account/organizations/:organization_id/csv_descriptor/edit
  def edit; end

  # PUT /account/organizations/:organization_id/csv_descriptor
  def update
    if @csv_descriptor.update(csv_descriptor_params)
      flash[:success] = 'Modifié avec succès.'

      redirect_to account_organization_path(@organization, tab: 'csv_descriptor')
    else
      render :edit
    end
  end

  private

  def verify_rights
    unless @user.is_admin || (@user.is_prescriber && @user.organization == @organization) || @organization.try(:csv_descriptor).try(:used?)
      flash[:error] = t('authorization.unessessary_rights')

      redirect_to account_organization_path(@organization)
    end
  end

  def load_csv_descriptor
    @csv_descriptor = @organization.csv_descriptor!
  end

  def csv_descriptor_params
    params.require(:software_csv_descriptor).permit(:directive, :comma_as_number_separator)
  end
end

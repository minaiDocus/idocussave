# -*- encoding : UTF-8 -*-
class Account::FileNamingPoliciesController < Account::OrganizationController
  before_filter :verify_rights
  before_filter :load_file_naming_policy

  def edit
  end

  def update
    if @file_naming_policy.update(file_naming_policy_params)
      flash[:success] = 'Modifié avec succès.'
      redirect_to account_organization_path(@organization, tab: 'file_naming_policy')
    else
      render 'edit'
    end
  end

  def preview
    @file_naming_policy.assign_attributes(file_naming_policy_params)
    file_name = CustomFileNameService.new(@file_naming_policy).execute({
      user_code:      'TS%00001',
      user_company:   'iDocus',
      journal:        'AC',
      period:         '201501',
      piece_number:   '001',
      third_party:    'Google',
      invoice_number: '001002',
      invoice_date:   '2015-01-02',
      extension:      '.pdf'
    })
    respond_to do |format|
      format.json { render json: { file_name: file_name } }
    end
  end

private

  def verify_rights
    unless is_leader?
      flash[:error] = t('authorization.unessessary_rights')
      redirect_to account_organization_path(@organization)
    end
  end

  def load_file_naming_policy
    @file_naming_policy = @organization.foc_file_naming_policy
  end

  def file_naming_policy_params
    params.require(:file_naming_policy).permit(
      :scope,
      :separator,
      :first_user_identifier,
      :first_user_identifier_position,
      :second_user_identifier,
      :second_user_identifier_position,
      :is_journal_used,
      :journal_position,
      :is_period_used,
      :period_position,
      :is_piece_number_used,
      :piece_number_position,
      :is_third_party_used,
      :third_party_position,
      :is_invoice_number_used,
      :invoice_number_position,
      :is_invoice_date_used,
      :invoice_date_position
    )
  end
end

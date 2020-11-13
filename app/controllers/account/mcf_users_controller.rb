# frozen_string_literal: true

class Account::McfUsersController < Account::OrganizationController
  before_action :load_mcf_settings
  before_action :verify_rights

  # GET /account/organizations/:organization_id/mcf_users
  def index
    respond_to do |format|
      if accounts.present?
        format.json { render json: accounts, status: :ok }
      else
        format.json { render json: 'Error', status: :unprocessable_entity }
      end
    end
  end

  private

  def verify_rights
    unless @mcf_settings.try(:configured?)
      flash[:error] = t('authorization.unessessary_rights')
      redirect_to account_organization_path(@organization)
    end
  end

  def load_mcf_settings
    @mcf_settings = @organization.mcf_settings
  end

  def accounts
    if @accounts.nil?
      _accounts = McfLib::Api::Mcf::Client.new(@mcf_settings.access_token).accounts
      if _accounts.present?
        @accounts = [{ name: 'Aucun', id: '' }] + _accounts.map { |account| { name: account, id: account } }
      else
        @accounts = nil
      end
    end
    @accounts
  end
end

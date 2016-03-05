# -*- encoding : UTF-8 -*-
class Account::IbizaUsersController < Account::OrganizationController
  before_filter :load_ibiza
  before_filter :verify_rights

  def index
    users = Rails.cache.read([:ibiza, @ibiza.id, :users])
    unless users
      @ibiza.get_users_without_delay
      users = Rails.cache.read([:ibiza, @ibiza.id, :users])
    end
    if users
      result = users.map do |user|
        { name: user.name, id: user.id }
      end
    else
      result = []
    end
    respond_to do |format|
      format.json { render json: result }
    end
  end

private

  def verify_rights
    unless @ibiza.try(:configured?)
      flash[:error] = t('authorization.unessessary_rights')
      redirect_to account_organization_path
    end
  end

  def load_ibiza
    @ibiza = @organization.ibiza
  end
end

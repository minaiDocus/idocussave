# -*- encoding : UTF-8 -*-
class Account::ExactOnlineUsersController < Account::OrganizationController
  before_filter :load_exact_online
  before_filter :verify_rights

  # GET /account/organizations/:organization_id/exact_online_users
  def index
    users = Rails.cache.read([:exact_online, @exact_online.id, :users])
    users = @exact_online.users unless users

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
    unless @exact_online.try(:used?)
      flash[:error] = t('authorization.unessessary_rights')
      redirect_to account_organization_path(@organization)
    end
  end


  def load_exact_online
    @exact_online = @organization.exact_online
  end
end

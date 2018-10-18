# -*- encoding : UTF-8 -*-
class Account::ExactUsersController < Account::OrganizationController
  before_filter :load_exact
  before_filter :verify_rights

  # GET /account/organizations/:organization_id/exact_users
  def index
    users = Rails.cache.read([:exact, @exact.id, :users])
    users = @exact.users unless users

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
    unless @exact.try(:used?)
      flash[:error] = t('authorization.unessessary_rights')
      redirect_to account_organization_path(@organization)
    end
  end


  def load_exact
    @exact = @organization.exact_online
  end
end

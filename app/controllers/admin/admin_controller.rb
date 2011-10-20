class Admin::AdminController < ApplicationController
  before_filter :authenticate_user!
  before_filter :verify_admin_rights

  layout "admin"

private

  def verify_admin_rights
    unless current_user.is_admin
       redirect_to root_url
    end
  end

public

  def index

  end
end

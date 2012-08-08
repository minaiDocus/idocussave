# -*- encoding : UTF-8 -*-
class Admin::AdminController < ApplicationController
  before_filter :authenticate_user!
  before_filter :verify_admin_rights

  layout 'admin'

  private

  def verify_admin_rights
    redirect_to root_url unless current_user.is_admin
  end

  public

  def index
  end
end

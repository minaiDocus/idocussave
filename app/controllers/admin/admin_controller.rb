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
  
  def format_params
    @formatted_last_name = ""
    @formatted_first_name = ""
    @formatted_last_name = params[:last_name].split.collect{|n| n.capitalize}.join(' ') if params[:last_name]
    @formatted_first_name = params[:first_name].upcase if params[:first_name]
  end

public

  def index

  end
end

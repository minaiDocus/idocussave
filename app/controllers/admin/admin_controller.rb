# -*- encoding : UTF-8 -*-
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
  
  def filtered_user_ids
    users = User.all
    
    if !params[:first_name].blank?
      formatted_first_name = params[:first_name].upcase
      users = users.where(:first_name => /\w*#{formatted_first_name}\w*/)
    end
    
    if !params[:last_name].blank?
      formatted_last_name = params[:last_name].split.collect{|n| n.capitalize}.join(' ')
      users = users.where(:last_name => /\w*#{formatted_last_name}\w*/)
    end
    
    users = users.where(:email => /\w*#{params[:email]}\w*/) if !params[:email].blank?
    users = users.where(:company => /\w*#{params[:company]}\w*/) if !params[:company].blank?
    users = users.where(:code => /\w*#{params[:code]}\w*/) if !params[:code].blank?
    
    if !params[:first_name].blank? || !params[:last_name].blank? || !params[:email].blank? || !params[:company].blank? || !params[:code].blank?
      @filtered_user_ids = users.entries.collect{|u| u.id}
    else
      @filtered_user_ids = []
    end
  end

public

  def index
    @events = Event.order_by(:created_at.desc).limit(3).entries
    @orders = Order.order_by(:created_at.desc, :number.desc).limit(3).entries
  end
end

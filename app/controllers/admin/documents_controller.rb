class Admin::DocumentsController < ApplicationController
  layout "admin"
  
  def index
    @user = nil
    unless params[:email].blank? && params[:first_name].blank? && params[:last_name].blank? && params[:company].blank? && params[:code].blank?
      users = User.where(:email => /\w*#{params[:email]}\w*/) if !params[:email].blank?
      users = User.where(:first_name => /\w*#{@formatted_first_name}\w*/) if !params[:first_name].blank?
      users = User.where(:last_name => /\w*#{@formatted_last_name}\w*/) if !params[:last_name].blank?
      users = User.where(:company => /\w*#{params[:company]}\w*/) if !params[:company].blank?
      users = User.where(:code => /\w*#{params[:code]}\w*/) if !params[:code].blank?
      @user = users.first
    end
    
    @packs = []
    
    if @user.try(:packs)
      @packs = @user.packs.sort do |a,b|
        a.created_at <=> b.created_at
      end
    end
    
    @packs = @packs.paginate :page => params[:page], :per_page => 50
    
  end

end

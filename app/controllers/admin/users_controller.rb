# -*- encoding : UTF-8 -*-
class Admin::UsersController < Admin::AdminController
  helper_method :sort_column, :sort_direction, :user_contains

  def index
    @users = search(user_contains).order([sort_column,sort_direction]).page(params[:page]).per(params[:per_page])
  end

  def show
    @user = User.find params[:id]
  end

  def update
    @user = User.find params[:id]
    respond_to do |format|
      if @user.update_attributes(params[:user])
        format.html { redirect_to [:admin,@user], notice: 'Modifié avec succès.' }
        format.json { respond_with_bip(@user) }
      else
        format.html { render action: :edit }
        format.json { respond_with_bip(@user) }
      end
    end
  end

  private

  def sort_column
    params[:sort] || 'created_at'
  end

  def sort_direction
    params[:direction] || 'desc'
  end

  def user_contains
    @contains ||= {}
    if params[:user_contains] && @contains.blank?
      @contains = params[:user_contains].delete_if do |key,value|
        if value.blank? && !value.is_a?(Hash)
          true
        elsif value.is_a? Hash
          value.delete_if { |k,v| v.blank? }
          value.blank?
        else
          false
        end
      end
    end
    @contains
  end

  def search(contains)
    users = User.all
    users = users.where(:first_name => /#{contains[:first_name]}/i) unless contains[:first_name].blank?
    users = users.where(:last_name => /#{contains[:last_name]}/i) unless contains[:last_name].blank?
    users = users.where(:email => /#{contains[:email]}/i) unless contains[:email].blank?
    users = users.where(:company => /#{contains[:company]}/i) unless contains[:company].blank?
    users = users.where(:code => /#{contains[:code]}/i) unless contains[:code].blank?
    users
  end
end
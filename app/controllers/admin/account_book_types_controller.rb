class Admin::AccountBookTypesController < ApplicationController
  layout "admin"
  
  before_filter :load_account_book_type, :only => %w(show edit update destroy)
  
private
  def load_account_book_type
    @account_book_type = AccountBookType.find_by_slug params[:id]
  end
  
public
  def index
    @account_book_types = AccountBookType.all.by_position
  end

  def show
  end

  def new
    @account_book_type = AccountBookType.new
  end
  
  def create
    @account_book_type = AccountBookType.new params[:account_book_type]
    if params[:user_ids]
      users = User.any_in(:_id => params[:user_ids]).entries
      @account_book_type.users = users
    end
    if @account_book_type.save
      users.each{|u| u.save} if params[:user_ids]
      redirect_to admin_account_book_types_path
    else
      render :action => "new"
    end
  end

  def edit
  end
  
  def update
    if params[:user_ids]
      users = User.any_in(:_id => params[:user_ids]).entries
      @account_book_type.users = users
    end
    if @account_book_type.update_attributes params[:account_book_type]
      users.each{|u| u.save} if params[:user_ids]
      redirect_to admin_account_book_types_path
    else
      render :action => "edit"
    end
  end

  def destroy
    @account_book_type.destroy
    redirect_to admin_account_book_types_path
  end

end

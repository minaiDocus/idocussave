# -*- encoding : UTF-8 -*-
class Admin::AccountBookTypesController < Admin::AdminController
  before_filter :load_user
  before_filter :load_account_book_type, except: 'index'

  layout :nil_layout

  private

  def load_user
    @user = User.find params[:user_id]
  end

  def load_account_book_type
    @account_book_type = AccountBookType.unscoped.find_by_slug params[:id]
  end

  public

  def index
    @account_book_types = @user.account_book_types.unscoped.by_position
    @requested_account_book_types = @user.requested_account_book_types.unscoped.by_position
  end

  def add
    respond_to do |format|
      @user.account_book_types << @account_book_type
      @account_book_type.update_request_status!([@user])
      format.json { render json: {}, status: :ok }
      format.html { redirect_to admin_user_path(@user), notice: 'Ajouté avec succès.' }
    end
  end

  def remove
    respond_to do |format|
      @account_book_type.clients = @account_book_type.clients - [@user]
      @user.account_book_types = @user.account_book_types.unscoped - [@account_book_type]
      @account_book_type.save
      @user.save
      @account_book_type.update_request_status!([@user])
      format.json { render json: {}, status: :ok }
      format.html { redirect_to admin_user_path(@user), notice: 'Retiré avec succès.' }
    end
  end
end

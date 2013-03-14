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

  def accept
    respond_to do |format|
      if @account_book_type.accept!
        @user.set_request_type!
        format.json { render json: {}, status: :ok }
        format.html { redirect_to admin_user_path(@user), notice: 'Modifié avec succès.' }
      else
        format.json { render json: @account_book_type.errors.to_json, status: :unprocessable_entity }
        format.html { redirect_to admin_user_path(@user), error: 'Impossible de modifier ce journal.' }
      end
    end
  end

  def add
    respond_to do |format|
      if @user.account_book_types << @account_book_type
        @user.set_request_type!
        format.json { render json: {}, status: :ok }
        format.html { redirect_to admin_user_path(@user), notice: 'Ajouté avec succès.' }
      else
        format.json { render json: @account_book_type.errors.to_json, status: :unprocessable_entity }
        format.html { redirect_to admin_user_path(@user), error: 'Impossible de modifier ce journal.' }
      end
    end
  end

  def remove
    respond_to do |format|
      @account_book_type.clients = @account_book_type.clients - [@user]
      @user.account_book_types = @user.account_book_types.unscoped - [@account_book_type]
      if @account_book_type.save
        @user.set_request_type!
        format.json { render json: {}, status: :ok }
        format.html { redirect_to admin_user_path(@user), notice: 'Retiré avec succès.' }
      else
        format.json { render json: @account_book_type.errors.to_json, status: :unprocessable_entity }
        format.html { redirect_to admin_user_path(@user), error: 'Impossible de modifier ce journal.' }
      end
    end
  end
end

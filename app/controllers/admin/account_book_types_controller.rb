# -*- encoding : UTF-8 -*-
class Admin::AccountBookTypesController < Admin::AdminController
  before_filter :load_user

  before_filter :load_account_book_type, only: %w(edit update destroy)

  layout :nil_layout

  private

  def load_user
    @user = User.find params[:user_id]
  end

  def load_account_book_type
    @account_book_type = AccountBookType.find_by_slug params[:id]
  end

  public

  def index
    if @user.is_prescriber
      @account_book_types = @user.my_account_book_types.by_position
    else
      @account_book_types = @user.account_book_types.by_position
    end
  end

  def new
    @account_book_type = AccountBookType.new
  end

  def create
    @account_book_type = AccountBookType.new(params[:account_book_type])
    @account_book_type.owner = @user
    respond_to do |format|
      if @account_book_type.save
        format.json { render json: {}, status: :ok }
        format.html { redirect_to admin_user_path(@user), notice: 'Créer avec succès.' }
      else
        format.json { render json: @account_book_type.errors.to_json, status: :unprocessable_entity }
        format.html { render action: :new }
      end
    end
  end

  def edit
  end

  def update
    respond_to do |format|
      if @account_book_type.update_attributes(params[:account_book_type])
        format.json { render json: {}, status: :ok }
        format.html { redirect_to admin_user_path(@user), notice: 'Modifié avec succès.' }
      else
        format.json { render json: @account_book_type.errors.to_json, status: :unprocessable_entity }
        format.html { render action: :new }
      end
    end
  end

  def destroy
    respond_to do |format|
      if @account_book_type.destroy
        format.json { render json: {}, status: :ok }
        format.html { redirect_to admin_user_path(@user), notice: 'Supprimé avec succès.' }
      else
        format.json { render json: @account_book_type.errors.to_json, status: :unprocessable_entity }
        format.html { redirect_to admin_user_path(@user), error: 'Impossible de supprimer ce journal' }
      end
    end
  end
end

# -*- encoding : UTF-8 -*-
class Admin::OrganizationJournalsController < Admin::AdminController
  before_filter :load_organization
  before_filter :load_account_book_type, only: %w(edit update destroy accept add remove)

  layout :nil_layout

  def index
    @account_book_types = @organization.account_book_types.unscoped.by_position
  end

  def new
    @account_book_type = AccountBookType.new
  end

  def create
    @account_book_type = AccountBookType.new(params[:account_book_type])
    @account_book_type.organization = @organization
    respond_to do |format|
      if @account_book_type.save
        format.json { render json: {}, status: :ok }
        format.html { redirect_to admin_organization_path(@organization), notice: 'Créer avec succès.' }
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
        format.html { redirect_to admin_organization_path(@organization), notice: 'Modifié avec succès.' }
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
        format.html { redirect_to admin_organization_path(@organization), notice: 'Supprimé avec succès.' }
      else
        format.json { render json: @account_book_type.errors.to_json, status: :unprocessable_entity }
        format.html { redirect_to admin_organization_path(@organization), error: 'Impossible de supprimer ce journal.' }
      end
    end
  end

  def accept
    respond_to do |format|
      if @account_book_type.accept!
        format.json { render json: {}, status: :ok }
        format.html { redirect_to admin_organization_path(@organization), notice: 'Modifié avec succès.' }
      else
        format.json { render json: @account_book_type.errors.to_json, status: :unprocessable_entity }
        format.html { redirect_to admin_organization_path(@organization), error: 'Impossible de modifier ce journal.' }
      end
    end
  end

private

  def load_account_book_type
    @account_book_type = AccountBookType.unscoped.find_by_slug params[:id]
  end

end

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
    @account_book_type = AccountBookType.new(account_book_type_params)
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
      old_requested_clients = @account_book_type.clients
      ids = (params[:account_book_type][:client_ids] || []).reject { |e| e.blank? }
      new_requested_clients = User.find(ids)
      added_clients = new_requested_clients - old_requested_clients
      removed_clients = old_requested_clients - new_requested_clients
      if @account_book_type.update_attributes(account_book_type_params)
        modified_users = (added_clients + removed_clients).map { |e| e.reload }
        @account_book_type.update_request_status!(modified_users)
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
      if @account_book_type.request.update_attribute(:action, '')
        format.json { render json: {}, status: :ok }
        format.html { redirect_to admin_organization_path(@organization), notice: 'Modifié avec succès.' }
      else
        format.json { render json: @account_book_type.errors.to_json, status: :unprocessable_entity }
        format.html { redirect_to admin_organization_path(@organization), error: 'Impossible de modifier ce journal.' }
      end
    end
  end

private

  def account_book_type_params
    params.require(:account_book_type).permit!
  end

  def load_account_book_type
    @account_book_type = AccountBookType.unscoped.find_by_slug params[:id]
  end

end

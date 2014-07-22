# -*- encoding : UTF-8 -*-
class Account::JournalsController < Account::OrganizationController
  before_filter :verify_rights
  before_filter :load_journal, except: %w(index new create)

  def index
    @journals = @organization.account_book_types.unscoped.asc(:name)
  end

  def new
    @journal = AccountBookType.new
  end

  def create
    if (@journal = AccountBookType.create journal_params)
      @organization.account_book_types << @journal
      flash[:success] = 'Créé avec succès.'
      redirect_to account_organization_journals_path
    else
      render action: 'new'
    end
  end

  def edit
  end

  def update
    respond_to do |format|
      if @journal.update_attributes(journal_params)
        format.json{ render json: @journal.to_json, status: :ok }
        format.html{ redirect_to account_organization_journals_path, flash: { success: 'Modifié avec succès.' } }
      else
        format.json{ render json: {}, status: :unprocessable_entity }
        format.html{ render action: 'edit' }
      end
    end
  end

  def destroy
    if @journal.destroy
      flash[:success] = 'Supprimé avec succès.'
    else
      flash[:error] = 'Impossible de supprimer.'
    end
    redirect_to account_organization_journals_path
  end

private

  def verify_rights
    unless is_leader? || @user.can_manage_journals?
      flash[:error] = t('authorization.unessessary_rights')
      redirect_to account_organization_path
    end
  end

  def journal_params
    attributes = params.require(:account_book_type).permit(
      :name,
      :pseudonym,
      :description,
      :position,
      :domain,
      :entry_type,
      :default_account_number,
      :account_number,
      :default_charge_account,
      :charge_account,
      :vat_account,
      :anomaly_account,
      :instructions,
      :is_default,
      :client_ids
    )
    attributes[:client_ids] = [] if attributes[:client_ids] == 'empty'
    if @journal && @journal.is_expense_categories_editable
      attributes.merge!(params.require(:account_book_type).permit(:expense_categories_attributes))
    end
    attributes
  end

  def load_journal
    begin
      @journal = @organization.account_book_types.unscoped.find(params[:id])
    rescue BSON::InvalidObjectId
      @journal = @organization.account_book_types.unscoped.find_by_slug(params[:id])
    end
  end
end

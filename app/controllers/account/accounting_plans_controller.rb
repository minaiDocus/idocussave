# -*- encoding : UTF-8 -*-
class Account::AccountingPlansController < Account::OrganizationController
  before_filter :verify_access
  before_filter :load_customer
  before_filter :verify_if_customer_is_active
  before_filter :redirect_to_current_step
  before_filter :load_accounting_plan
  before_filter :verify_rights

  # GET /account/organizations/:organization_id/customers/:customer_id/accounting_plan
  def show
  end


  # GET /account/organizations/:organization_id/customers/:customer_id/accounting_plan/edit
  def edit
  end


  # PUT /account/organizations/:organization_id/customers/:customer_id/accounting_plan/:id
  def update
    if @accounting_plan.update(accounting_plan_params)
      flash[:success] = 'Modifié avec succès.'

      redirect_to account_organization_customer_accounting_plan_path(@organization, @customer)
    else
      render :edit
    end
  end


  # GET /account/organizations/:organization_id/customers/:customer_id/accounting_plan/import_model
  def import_model
    data = "NOM_TIERS;COMPTE_TIERS;COMPTE_CONTREPARTIE;CODE_TVA\n"

    send_data(data, type: 'plain/text', filename: "modèle d'import.csv")
  end


  # PUT /account/organizations/:organization_id/customers/:customer_id/accounting_plan/import
  def import
    if params[:providers_file]
      file = params[:providers_file]
      type = 'providers'
    elsif params[:customers_file]
      file = params[:customers_file]
      type = 'customers'
    end

    if file
      if @accounting_plan.import(file, type)
        flash[:success] = 'Importé avec succès.'
      else
        flash[:error] = 'Fichier non valide.'
      end
    else
      flash[:error] = 'Aucun fichier choisi.'
    end

    redirect_to account_organization_customer_accounting_plan_path(@organization, @customer)
  end


  # DELETE /account/organizations/:organization_id/customers/:customer_id/accounting_plan/destroy_providers
  def destroy_providers
    @accounting_plan.providers.clear

    @accounting_plan.save

    flash[:success] = 'Fournisseurs supprimés avec succès.'

    redirect_to account_organization_customer_accounting_plan_path(@organization, @customer)
  end


  # DELETE /account/organizations/:organization_id/customers/:customer_id/accounting_plan/destroy_customers
  def destroy_customers
    @accounting_plan.customers.clear

    @accounting_plan.save

    flash[:success] = 'Clients supprimés avec succès.'

    redirect_to account_organization_customer_accounting_plan_path(@organization, @customer)
  end

  private

  def verify_access
    if @organization.ibiza.try(:access_token).present?
      flash[:error] = t('authorization.unessessary_rights')

      redirect_to account_organization_path(@organization)
    end
  end


  def load_customer
    @customer = customers.find params[:customer_id]
  end


  def verify_if_customer_is_active
    if @customer.inactive?
      flash[:error] = t('authorization.unessessary_rights')

      redirect_to account_organization_path(@organization)
    end
  end


  def load_accounting_plan
    @accounting_plan = @customer.accounting_plan
  end


  def verify_rights
    unless is_leader? || @user.can_manage_customers?
      flash[:error] = t('authorization.unessessary_rights')
      redirect_to account_organization_path(@organization)
    end
  end


  def accounting_plan_params
    attributes = {}

    if params[:accounting_plan]
      if params[:accounting_plan][:providers_attributes].present?
        attributes[:providers_attributes] = params[:accounting_plan][:providers_attributes].permit!
      end

      if params[:accounting_plan][:customers_attributes].present?
        attributes[:customers_attributes] = params[:accounting_plan][:customers_attributes].permit!
      end
    end

    attributes
  end
end

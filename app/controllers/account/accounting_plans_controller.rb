# -*- encoding : UTF-8 -*-
class Account::AccountingPlansController < Account::OrganizationController
  before_filter :verify_access
  before_filter :load_customer
  before_filter :load_accounting_plan
  before_filter :verify_rights

  def show
  end

  def edit
  end

  def update
    if @accounting_plan.update_attributes(accounting_plan_params)
      flash[:success] = 'Modifié avec succès.'
      redirect_to account_organization_customer_accounting_plan_path(@customer)
    else
      render action: 'edit'
    end
  end

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
    redirect_to account_organization_customer_accounting_plan_path(@customer)
  end

  def destroy_providers
    @accounting_plan.providers.clear
    @accounting_plan.save
    flash[:success] = 'Fournisseurs supprimé avec succès.'
    redirect_to account_organization_customer_accounting_plan_path(@customer)
  end

  def destroy_customers
    @accounting_plan.customers.clear
    @accounting_plan.save
    flash[:success] = 'Clients supprimé avec succès.'
    redirect_to account_organization_customer_accounting_plan_path(@customer)
  end

private

  def verify_access
    if @organization.ibiza.try(:token).present?
      flash[:error] = t('authorization.unessessary_rights')
      redirect_to account_organization_path
    end
  end

  def load_customer
    @customer = customers.find_by_slug params[:customer_id]
  end

  def load_accounting_plan
    @accounting_plan = @customer.accounting_plan
  end

  def verify_rights
    unless is_leader? || @user.can_manage_customers?
      flash[:error] = t('authorization.unessessary_rights')
      redirect_to account_organization_path
    end
  end

  def accounting_plan_params
    params.require(:accounting_plan).permit(:providers_attributes, :customers_attributes)
  end
end

# frozen_string_literal: true

class Account::AccountingPlansController < Account::OrganizationController
  before_action :load_customer
  before_action :verify_rights
  before_action :verify_if_customer_is_active
  before_action :redirect_to_current_step
  before_action :load_accounting_plan

  # GET /account/organizations/:organization_id/customers/:customer_id/accounting_plan
  def show
    if params[:format].present?
      FileUtils.rm params[:format], force: true
      redirect_to account_organization_customer_accounting_plan_path(@organization, @customer)
    end
  end

  # GET /account/organizations/:organization_id/customers/:customer_id/accounting_plan/edit
  def edit; end

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
    if params[:new_create_book_type].present?
      redirect_to new_customer_step_two_account_organization_customer_path(@organization, @customer)
    else
      redirect_to account_organization_customer_accounting_plan_path(@organization, @customer)
    end
  end

  def import_fec
    if params[:fec_file].present?
      return false if params[:fec_file].content_type != "text/plain"

      @dir = "#{Rails.root}/files/imports/FEC/"
      FileUtils.makedirs(@dir)
      FileUtils.chmod(0777, @dir)

      @file   = File.join(@dir, "file_#{Time.now.strftime('%Y%m%d%H%M')}.txt")
      journal = []

      FileUtils.cp params[:fec_file].path, @file

      @params_fec = ImportFecService.new(@file).parse_metadata

      @customer.account_book_types.each { |jl| journal << jl.name }

      @params_fec = @params_fec.merge(dir: @dir, file: @file, journal_ido: journal)
    else
      flash[:error] = 'Aucun fichier choisi.'
    end

    if params[:new_create_book_type].present?
      redirect_to new_customer_step_two_account_organization_customer_path(@organization, @customer)
    else
      render :show
    end
  end

  def import_fec_processing
    file_path  = params[:file_path]

    ImportFecService.new(file_path).execute(@customer, params)

    FileUtils.remove_entry params[:dir_tmp] if params[:dir_tmp]

    if params[:new_create_book_type].present?
      redirect_to new_customer_step_two_account_organization_customer_path(@organization, @customer)
    else
      redirect_to account_organization_customer_accounting_plan_path(@organization, @customer)
    end
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
    unless (@user.leader? || @user.manage_customers) && !@customer.uses_api_softwares?
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

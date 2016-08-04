# -*- encoding : UTF-8 -*-
class Account::AccountNumberRulesController < Account::OrganizationController
  before_filter :load_account_number_rule, only: %w(show edit update destroy)

  def index
    @account_number_rules = search(account_number_rule_contains).order_by(sort_column => sort_direction).page(params[:page]).per(params[:per_page])
  end

  def show
  end

	def new
    @account_number_rule = AccountNumberRule.new
    if params[:template].present?
      template = @organization.account_number_rules.find params[:template]
      @account_number_rule.name                = template.name_pattern + " (#{template.similar_name.size + 1})"
      @account_number_rule.affect              = template.affect
      @account_number_rule.rule_type           = template.rule_type
      @account_number_rule.content             = template.content
      @account_number_rule.third_party_account = template.third_party_account
      @account_number_rule.priority            = template.priority
      @account_number_rule.users               = template.users
    end
  end

  def create
    @account_number_rule = AccountNumberRule.new account_number_rule_params
    @account_number_rule.organization = @organization
    if @account_number_rule.save
      flash[:success] = 'Créé avec succès.'
      redirect_to account_organization_account_number_rule_path(@organization, @account_number_rule)
    else
      render 'new'
    end
  end

  def edit
  end

  def update
    # re-assign customers of other collaborators
    if params[:account_number_rule] && params[:account_number_rule][:user_ids].present?
      params[:account_number_rule][:user_ids] += (@account_number_rule.users - customers).map(&:id).map(&:to_s)
    end
    if @account_number_rule.update(account_number_rule_params)
      flash[:success] = 'Modifié avec succès.'
      redirect_to account_organization_account_number_rules_path(@organization)
    else
      render 'edit'
    end
  end

  def destroy
    @account_number_rule.destroy
    flash[:success] = 'Supprimé avec succès.'
    redirect_to account_organization_account_number_rules_path(@organization)
  end

  def export_or_destroy
    @account_number_rules = AccountNumberRule.where(:_id.in => params[:rules].try(:[], :rule_ids) || [])
    if @account_number_rules.any?
      case params[:export_or_destroy]
        when 'export'
          data = AccountNumberRulesToXlsService.new(@account_number_rules).execute
          send_data data, type: 'application/vnd.ms-excel', filename: 'Affectation.xls'
        when 'destroy'
          @account_number_rules.destroy_all
          flash[:success] = "Règles d'affectations supprimées avec succès."
          redirect_to account_organization_account_number_rules_path(@organization)
      end
    else
      flash[:warning] = "Veuillez sélectionner les règles d'affectations à exporter ou à supprimer."
      redirect_to account_organization_account_number_rules_path(@organization)
    end
  end

  def import_model
    data = [
      ['PRIORITE;NOM;TYPE;CATEGORISATION;CONTENU_RECHERCHE;NUMERO_COMPTE'],
      ['0;AYM GAN;RECHERCHE;BANQUE;PRLV SEPA GAN;0GAN'],
      ['0;EXO;CORRECTION;IMPOT;EXO;']
    ]
    send_data(data.join("\n"), type: 'plain/text', filename: "modèle d'import.csv")
  end

  def import_form
  end

  def import
    file = params[:file]
    if file
      if AccountNumberRule.import(file, params[:account_number_rule], @organization)
        flash[:success] = 'Importé avec succès.'
      else
        flash[:error] = 'Fichier non valide.'
      end
    else
      flash[:error] = 'Aucun fichier choisi.'
    end
    redirect_to account_organization_account_number_rules_path(@organization)
  end

private

  def sort_column
    params[:sort] || 'name'
  end
  helper_method :sort_column

  def sort_direction
    params[:direction] || 'asc'
  end
  helper_method :sort_direction

  def account_number_rule_params
    attributes = [
      :name,
      :rule_type,
      :content,
      :priority,
      :third_party_account,
      :categorization
    ]
    params[:account_number_rule][:third_party_account] = nil if params[:account_number_rule][:rule_type] == 'truncate'
    attributes << :affect if action_name == 'create'
    if @account_number_rule.try(:persisted?)
      attributes << { user_ids: [] } if @account_number_rule.affect == 'user'
    elsif params[:account_number_rule][:affect] == 'user'
      attributes << { user_ids: [] }
    end
    params.require(:account_number_rule).permit(*attributes)
  end

  def load_account_number_rule
    @account_number_rule = @organization.account_number_rules.find params[:id]
  end

  def account_number_rule_contains
    @contains ||= {}
    if params[:account_number_rule_contains] && @contains.blank?
      @contains = params[:account_number_rule_contains].delete_if do |key,value|
        if value.blank? && !value.is_a?(Hash)
          true
        elsif value.is_a? Hash
          value.delete_if { |k,v| v.blank? }
          value.blank?
        else
          false
        end
      end
    end
    @contains
  end

  def search(contains)
    rules = @organization.account_number_rules
    rules = rules.where(name:                /#{Regexp.quote(contains[:name])}/i)    if contains[:name].present?
    rules = rules.where(affect:              contains[:affect])                      if contains[:affect].present?
    rules = rules.where(rule_type:           contains[:rule_type])                   if contains[:rule_type].present?
    rules = rules.where(content:             /#{Regexp.quote(contains[:content])}/i) if contains[:content].present?
    rules = rules.where(third_party_account: /#{Regexp.quote(contains[:third_party_account])}/i) if contains[:third_party_account].present?
    rules = rules.where(categorization:      /#{Regexp.quote(contains[:categorization])}/i) if contains[:categorization].present?
    if contains[:affect] != 'organization' && contains[:customer_code].present?
      user_ids = @organization.customers.where(code: /#{Regexp.quote(contains[:customer_code])}/i).map(&:_id)
      rules = rules.where(:user_ids.in => user_ids)   
    end
    rules
  end

end

# -*- encoding : UTF-8 -*-
class Account::AccountNumberRulesController < Account::OrganizationController
  before_filter :verify_rights
  before_filter :load_account_number_rule, except: %w(new create)

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
      redirect_to account_organization_path(@organization, tab: 'account_number_rules')
    else
      render 'edit'
    end
  end

  def destroy
    @account_number_rule.destroy
    flash[:success] = 'Supprimé avec succès.'
    redirect_to account_organization_path(@organization, tab: 'account_number_rules')
  end

private

  def account_number_rule_params
    attributes = [
      :name,
      :rule_type,
      :content,
      :priority,
      :third_party_account
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

  def verify_rights
    unless @organization.ibiza.try(:is_configured?)
      flash[:error] = t('authorization.unessessary_rights')
      redirect_to account_organization_path(@organization)
    end
  end
end

# -*- encoding : UTF-8 -*-
class Account::AccountNumberRulesController < Account::OrganizationController
  before_filter :load_account_number_rule, except: %w(new create)

  def show
  end

	def new
    @account_number_rule = AccountNumberRule.new
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
    params[:account_number_rule][:user_ids] += (@account_number_rule.users - customers).map(&:id).map(&:to_s)
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
end

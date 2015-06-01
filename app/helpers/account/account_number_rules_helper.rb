module Account::AccountNumberRulesHelper
  def affect_options_for_select
    [
      [t('mongoid.models.account_number_rule.attributes.affect_values.organization'), 'organization'],
      [t('mongoid.models.account_number_rule.attributes.affect_values.user'), 'user']
    ]
  end

  def rule_type_options_for_select
    [
      [t('mongoid.models.account_number_rule.attributes.rule_type_values.match'), 'match'],
      [t('mongoid.models.account_number_rule.attributes.rule_type_values.truncate'), 'truncate']
    ]
  end
end

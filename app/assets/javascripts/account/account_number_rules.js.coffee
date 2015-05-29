jQuery ->
  if $('#account_number_rule_affect').val() == "organization"
      $("input[name='account_number_rule[user_ids][]']").parent().parent().hide()
  if $('#account_number_rule_rule_type').val() == "truncate"
      $('#account_number_rule_third_party_account').parent().parent().hide()

  $('#account_number_rule_affect').on 'change', ->
    if $(this).val() == "organization"
      $("input[name='account_number_rule[user_ids][]']").parent().parent().hide()
    else
      $("input[name='account_number_rule[user_ids][]']").parent().parent().show()

  $('#account_number_rule_rule_type').on 'change', ->
    if $(this).val() == "truncate"
      $('#account_number_rule_third_party_account').parent().parent().hide()
    else
      $('#account_number_rule_third_party_account').parent().parent().show()
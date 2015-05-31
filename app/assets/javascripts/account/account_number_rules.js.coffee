jQuery ->
  $anr_user_ids = $("input[name='account_number_rule[user_ids][]']").parent().parent()
  $anr_third_party_account = $('#account_number_rule_third_party_account').parent().parent()

  if $('#account_number_rule_affect').val() == 'organization'
    $anr_user_ids.hide()
  if $('#account_number_rule_rule_type').val() == 'truncate'
    $anr_third_party_account.hide()

  $('#account_number_rule_affect').on 'change', ->
    if $(this).val() == 'organization'
      $anr_user_ids.hide()
    else
      $anr_user_ids.show()

  $('#account_number_rule_rule_type').on 'change', ->
    if $(this).val() == 'truncate'
      $anr_third_party_account.hide()
    else
      $anr_third_party_account.show()

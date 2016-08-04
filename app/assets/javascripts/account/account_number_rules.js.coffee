update_groups = ->
  ids = ''
  $("input[name='account_number_rule[user_ids][]']").each (index, element) =>
    if $(element).attr('checked')
      ids += ' ' + $(element).val()
  $("input[name='account_number_rule[group][]']").each (index, element) =>
    if $(element).attr('checked')
      ids += ' ' + $(element).val()
    else
      for id in $(element).val().split(' ')
        ids = ids.replace(id, '')
  $("input[name='account_number_rule[user_ids][]']").attr('checked', false)
  for id in ids.split(' ')
    $('#account_number_rule_user_ids_' + id).attr('checked', true)

jQuery ->
  $anr_third_party_account = $('#account_number_rule_third_party_account').parent().parent()
  $anr_affect_to = $('.affect_to')

  if $('#account_number_rule_affect').val() == 'user'
    $anr_affect_to.show()

  if $('#account_number_rule_rule_type').val() == 'truncate'
    $anr_third_party_account.hide()

  $('#account_number_rule_affect').on 'change', ->
    if $(this).val() == 'organization'
      $anr_affect_to.hide()
    else
      $anr_affect_to.show()

  $('#account_number_rule_rule_type').on 'change', ->
    if $(this).val() == 'truncate'
      $anr_third_party_account.hide()
    else
      $anr_third_party_account.show()

  $('.all_groups').click (e) ->
    $("input[name='account_number_rule[group][]']").attr('checked', true)
    update_groups()
  $('.no_groups').click (e) ->
    $("input[name='account_number_rule[group][]']").attr('checked', false)
    update_groups()

  $('.all_users').click (e) ->
    $("input[name='account_number_rule[user_ids][]']").attr('checked', true)
  $('.no_users').click (e) ->
    $("input[name='account_number_rule[user_ids][]']").attr('checked', false)

  $("input[name='account_number_rule[group][]']").on 'change', ->
    update_groups()

  if $('#account_number_rules.select_to_download').length > 0
    $('#master_checkbox').change ->
      if $(this).is(':checked')
        $('.checkbox').attr('checked', true);
      else
        $('.checkbox').attr('checked', false);

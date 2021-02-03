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

  if $("#account_number_rule_affect_user").is(':checked')
    $anr_affect_to.show()

  if $('#account_number_rule_rule_type').val() == 'truncate'
    $anr_third_party_account.hide()

  $("#account_number_rule_affect_user").click (e) ->
    $anr_affect_to.show()

  $("#account_number_rule_affect_organization").click (e) ->
    $anr_affect_to.hide()


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


  if $('#skipAccountingPlan .searchable-option-list').length > 0
    $('#skipAccountingPlan .searchable-option-list').searchableOptionList(
      showSelectionBelowList: true,
      showSelectAll: true,
      maxHeight: '300px',
      texts: {
        noItemsAvailable:  'Aucune entrée trouvée',
        selectAll:         'Sélectionner tout',
        selectNone:        'Désélectionner tout',
        quickDelete:       '&times;',
        searchplaceholder: 'Cliquer ici pour rechercher'
      }
    )

  $('#skipAccountingPlan #skipAccountingPlanButton').on 'click', ->
    accounts = $('#skipAccountingPlan #account_list').val()
    account_validation = $('#skipAccountingPlan #account_validation').val()
    url = $('#skipAccountingPlan #skipAccountingPlanForm').attr('action')

    $.ajax({
      url: url,
      data: { account_list: accounts, account_validation: account_validation },
      dataType: 'json',
      type: 'post',
      beforeSend: () ->
        $('#skipAccountingPlan .parentFeedback').show()
        $('#skipAccountingPlan #skipAccountingPlanButton').attr('disabled', 'disabled')
      success: (data) ->
        $('#skipAccountingPlan .parentFeedback').hide()
        $('#skipAccountingPlan #skipAccountingPlanButton').removeAttr('disabled', 'disabled')
        $('#skipAccountingPlan').modal('hide')
      error: (data) ->
        $('#skipAccountingPlan .parentFeedback').hide()
        $('#skipAccountingPlan #skipAccountingPlanButton').removeAttr('disabled', 'disabled')
    })
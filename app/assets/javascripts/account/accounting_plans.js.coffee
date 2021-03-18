launch_request = (_url, _data, customer_id, organization_id) ->
  $.ajax(
    type: 'POST',
    url: '/account/organizations/' + organization_id + '/customers/' + customer_id + '/accounting_plan/' + _url,
    contentType: 'application/json',
    data: _data).success (response) ->
    alert_element = ''

    if response['success'] == true
      alert_element = '<div class="alert alert-success col-sm-12"><a class="close" data-dismiss="alert">×</a><div id="flash_alert-success">' + response['message'] + '</div></div>'
    else
      alert_element = '<div class="alert alert-danger col-sm-12"><a class="close" data-dismiss="alert">×</a><div id="flash_alert-danger">' + response['message'] + '</div></div>'

    $('.alerts').html('<div class="row-fluid">' + alert_element + '</div>')

delete_part_account = () ->
  $('.delete_part_account').on 'click', (e) ->
    e.preventDefault()
    $(this).parent().remove()

jQuery ->
  if ($('#import_dialog').length > 0)
    $('#import_dialog').modal('show')

  if ($('.import_dialog').length > 0)
    $('.import_dialog').modal('show')

  $('#import_button').click (e) ->
    e.preventDefault()
    $(this).attr('disabled', true)
    if ($('select.piece').val() == '')
      alert('Veuillez sélectionner la colonne pour la référence des pièces svp !')
      $(this).removeAttr('disabled')
      return false
    else
      $('#import_dialog #importFecAfterConfiguration').submit()

  $('#user_softwares_attributes_is_ibiza_auto_updating_accounting_plan_true, #user_softwares_attributes_is_ibiza_auto_updating_accounting_plan_false').click (e) ->
    e.preventDefault()
    is_ibiza_auto_updating_accounting_plan = 0
    _element = $(this).attr('info')
    element = _element.split('-')

    if $(this).val() == 'true'
      is_ibiza_auto_updating_accounting_plan = 1

    _url = 'ibiza_auto_update'

    _data = JSON.stringify(is_ibiza_auto_updating_accounting_plan: is_ibiza_auto_updating_accounting_plan)

    launch_request(_url, _data, element[1], element[0])

  $('.close_modal_fec').click (e) ->
    $(this).attr('disabled', true)
    $(this).html('<img src="/assets/application/bar_loading.gif" alt="chargement..." >')


  $('.mask_verif_account, .part_account').keyup ->
    value = $(this).val()

    regex = /^\d+$/

    if !regex.exec(value)
      $(this).val('')

  delete_part_account()
  $('#add_part_account').on 'click', (e) ->
    e.preventDefault()
    $('.counter_part_account').append($('.add_part_account').html())
    delete_part_account()
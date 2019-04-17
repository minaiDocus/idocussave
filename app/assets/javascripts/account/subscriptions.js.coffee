update_form = ->
  options = ['period_duration', 'number_of_journals', 'pre_assignment']
  selected_options = []
  
  $('.package input').each((e)->
    if !$(this).hasClass('commitment_pending')
      $(this).removeAttr('disabled')
  )

  if $('.package').hasClass('locked')
    if $('.package').hasClass('ligth_package_locked')
      $('.package input').attr('disabled', 'disabled')
  else
    $('.package input').removeAttr('disabled')

  if $('#subscription_is_basic_package_active').is(':checked')
    selected_options.push 'period_duration', 'number_of_journals', 'pre_assignment'
    lock_heavy_package()
  if $('#subscription_is_mail_package_active').is(':checked')
    selected_options.push 'period_duration', 'number_of_journals', 'pre_assignment'
    lock_heavy_package()
  if $('#subscription_is_scan_box_package_active').is(':checked')
    selected_options.push 'period_duration', 'number_of_journals', 'pre_assignment'
    lock_heavy_package()
  if $('#subscription_is_retriever_package_active').is(':checked')
    selected_options.push 'period_duration', 'number_of_journals'
    $('#subscription_is_annual_package_active').attr('disabled', 'disabled')
    $('#subscription_is_micro_package_active').attr('disabled', 'disabled')
  else
    $('.retriever_package_warning').hide()

  if $('#subscription_is_annual_package_active').is(':checked')
    selected_options.push 'number_of_journals'
    $('.package .light_package').attr('disabled', 'disabled')
  if $('#subscription_is_micro_package_active').is(':checked')
    selected_options.push 'period_duration', 'number_of_journals', 'pre_assignment'
    lock_light_package()
    $('#subscription_is_retriever_package_active').attr('disabled', 'disabled')
    $('#subscription_is_annual_package_active').attr('disabled', 'disabled')
    $('#subscription_is_mini_package_active').attr('disabled', 'disabled')
    $('.micro_package_warning').show()
  else 
    $('.micro_package_warning').hide() 
  if $('#subscription_is_mini_package_active').is(':checked')
    selected_options.push 'period_duration', 'number_of_journals', 'pre_assignment'
    lock_light_package()
    $('#subscription_is_annual_package_active').attr('disabled', 'disabled')
    $('#subscription_is_micro_package_active').attr('disabled', 'disabled')

  for option in options
    if selected_options.indexOf(option) != -1
      $('.'+option).show()
      if (option == 'pre_assignment')
        if $('#is_pre_assignment_active_hidden').val() > 0
          $('#subscription_is_pre_assignment_active_true').prop('checked', true)
    else
      $('.'+option).hide()

update_warning = ->
  to_be_disabled_text = null
  if $('#subscription_period_duration').val() == '1'
    to_be_disabled_text = "sera effectif le mois prochain"
  else if $('#subscription_period_duration').val() == '3'
    to_be_disabled_text = "sera effectif le trimestre prochain"
  is_recently_created = $('form').data('is-recently-created') == true

  if $('#subscription_is_basic_package_active').is(':checked')
    $('.basic_package_disable_warning').remove()
  else if $('#subscription_is_basic_package_active').data('original-value') == 1 && !is_recently_created
    unless $('.basic_package_disable_warning').length > 0
      $('#subscription_is_basic_package_active').parent('label').append('<b class="badge-inline badge badge-warning fs-origin basic_package_disable_warning">'+to_be_disabled_text+'</b>')

  if $('#subscription_is_mail_package_active').is(':checked')
    $('.mail_package_disable_warning').remove()
  else if $('#subscription_is_mail_package_active').data('original-value') == 1 && !is_recently_created
    unless $('.mail_package_disable_warning').length > 0
      $('#subscription_is_mail_package_active').parent('label').append('<b class="badge-inline badge badge-warning fs-origin mail_package_disable_warning">'+to_be_disabled_text+'</b>')

  if $('#subscription_is_scan_box_package_active').is(':checked')
    $('.scan_box_package_disable_warning').remove()
  else if $('#subscription_is_scan_box_package_active').data('original-value') == 1 && !is_recently_created
    unless $('.scan_box_package_disable_warning').length > 0
      $('#subscription_is_scan_box_package_active').parent('label').append('<b class="badge-inline badge badge-warning fs-origin scan_box_package_disable_warning">'+to_be_disabled_text+'</b>')

  if $('#subscription_is_micro_package_active').is(':checked')
    $('.micro_package_disable_warning').remove()
  else if $('#subscription_is_micro_package_active').data('original-value') == 1 && !is_recently_created
    unless $('.micro_package_disable_warning').length > 0
      $('#subscription_is_micro_package_active').parent('label').append('<b class="badge-inline badge badge-warning fs-origin micro_package_disable_warning">'+to_be_disabled_text+'</b>')

  if $('#subscription_is_mini_package_active').is(':checked')
    $('.mini_package_disable_warning').remove()
  else if $('#subscription_is_mini_package_active').data('original-value') == 1 && !is_recently_created
    unless $('.mini_package_disable_warning').length > 0
      $('#subscription_is_mini_package_active').parent('label').append('<b class="badge-inline badge badge-warning fs-origin mini_package_disable_warning">'+to_be_disabled_text+'</b>')

  if $('#subscription_is_retriever_package_active').is(':checked')
    $('.retriever_package_disable_warning').remove()
    if !$('#subscription_is_micro_package_active').is(':checked') && !$('#subscription_is_basic_package_active').is(':checked') && !$('#subscription_is_mail_package_active').is(':checked') && !$('#subscription_is_scan_box_package_active').is(':checked')
      $('.retriever_package_warning').show()
    else
      $('.retriever_package_warning').hide()
  else if $('#subscription_is_retriever_package_active').data('original-value') == 1 && !is_recently_created
    $('.retriever_package_warning').hide()
    unless $('.retriever_package_disable_warning').length > 0
      $('#subscription_is_retriever_package_active').parent('label').append('<b class="badge-inline badge badge-warning fs-origin retriever_package_disable_warning">'+to_be_disabled_text+'</b>')

  if $('#subscription_is_pre_assignment_active_true').is(':checked')
    $('.pre_assignment_disable_warning').remove()
  else if $('#subscription_is_pre_assignment_active_true').data('original-value') == 1 && !is_recently_created
    unless $('.pre_assignment_disable_warning').length > 0
      $('#subscription_is_pre_assignment_active_false').parent('label').parent('.choice').after('<div class="pre_assignment_disable_warning"><b class="badge-inline badge badge-warning fs-origin">'+to_be_disabled_text+'</b></div>')

lock_heavy_package = ->
  $('#subscription_is_annual_package_active').attr('disabled', 'disabled')
  $('#subscription_is_micro_package_active').attr('disabled', 'disabled')
  $('#subscription_is_mini_package_active').attr('disabled', 'disabled')

lock_light_package = ->
  $('#subscription_is_basic_package_active').attr('disabled', 'disabled')
  $('#subscription_is_mail_package_active').attr('disabled', 'disabled')
  $('#subscription_is_scan_box_package_active').attr('disabled', 'disabled')

update_price = ->
  price_list = {
    #standard prices
    'subscription':        [10,   30,   null],
    'pre_assignment':      [9,    15,   null],
    'return_paper':        [10,   10,   null],
    'retriever':           [5,    15,   null],
    'reduced_retriever':   [3,    9,    null],
    'annual_subscription': [null, null, 199],
     #special prices
    'subscription_plus':   [1, 3, null],
  }
  selected_options = []
  price = 0
  period_type = 0

  options = []
  if $('#subscription_is_annual_package_active').is(':checked')
    $('#subscription_period_duration').val(3)
    period_type = 2
    $('.stamp_price').html('(-€HT)')

    selected_options = ['annual_subscription']
  else
    period_duration = $('#subscription_period_duration').val()
    if period_duration == '1'
      period_type = 0
      $('.stamp_price').html('(5€HT)')
    else if period_duration == '3'
      period_type = 1
      $('.stamp_price').html('(15€HT)')


    if $('#subscription_is_basic_package_active').is(':checked')
      options.push 'subscription', 'subscription_plus', 'pre_assignment'
    if $('#subscription_is_mail_package_active').is(':checked')
      options.push 'subscription', 'subscription_plus', 'pre_assignment', 'return_paper'
    if $('#subscription_is_scan_box_package_active').is(':checked')
      options.push 'subscription', 'subscription_plus', 'pre_assignment'
    if $('#subscription_is_retriever_package_active').is(':checked')
      options.push $('#subscription_is_retriever_package_active').data('retriever-price-option')
    if $('#subscription_is_micro_package_active').is(':checked')
      options.push 'subscription'
    if $('#subscription_is_mini_package_active').is(':checked')
      options.push 'subscription', 'subscription_plus', 'pre_assignment'
    options = _.uniq(options)


    for option in options
      if option == 'pre_assignment'
        if $('#subscription_is_pre_assignment_active_true').is(':checked')
          selected_options.push 'pre_assignment'
      else
        selected_options.push option

  if options.length > 0
    number_of_journals = parseInt($('input[name="subscription[number_of_journals]"]:checked').val())
    if number_of_journals > 5
      price += number_of_journals - 5

  if $('.extra_options').length > 0
    for input in $('.extra_options input:checked')
      price += $(input).data('price')

  for option in selected_options
    price += price_list[option][period_type]

  $('.total_price').html(price+",00€ HT")

check_disabled_options = ->
  $('#subscription_package_form input:checkbox').each(->
    if $(this).attr('disabled') == 'disabled'
      hidden = $("#subscription_package_form input:hidden[name='"+$(this).attr('name')+"']")
      if hidden
        hidden.val($(this).is(':checked'))
      else
        $(this).after('<input type="hidden" name="'+$(this).attr('name')+'" value="'+$(this).is(':checked')+'">')
  )

refresh_softwares = (obj)->
  if(obj.attr('id') == 'softwares_is_ibiza_used' && obj.is(':checked'))
    $('#softwares_is_exact_online_used').removeAttr('checked')
  else if(obj.attr('id') == 'softwares_is_exact_online_used' && obj.is(':checked'))
    $('#softwares_is_ibiza_used').removeAttr('checked')

jQuery ->
  if $('#subscriptions.edit, #organization_subscriptions.edit').length > 0
    update_form()
    update_warning()
    update_price()

    $('#subscriptions #admin_options_button').on 'click', ->
      if $('#subscriptions .admin_options').is(':visible')
        $('#subscriptions .admin_options').fadeOut('fast')
      else
        $('#subscriptions .admin_options').fadeIn('fast')

    $('.package input').on 'change', ->
      update_form()

    $('input, select').on 'change', ->
      update_warning()
      update_price()

    $('#subscription_package_form').on 'submit', ->
      check_disabled_options()

    $('.softwares_setting').on 'click', ->
      refresh_softwares($(this))


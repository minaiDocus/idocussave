update_form = ->
  options = ['period_duration', 'number_of_journals', 'pre_assignment', 'stamp', 'scanner']
  selected_options = []

  if $('.package').hasClass('locked')
    if $('.package').hasClass('ligth_package_locked')
      $('.package input').attr('disabled', 'disabled')
  else
    $('.package input').removeAttr('disabled')

  if $('#subscription_is_basic_package_active').is(':checked')
    selected_options.push 'period_duration', 'number_of_journals', 'pre_assignment'
    $('#subscription_is_annual_package_active').attr('disabled', 'disabled')
  if $('#subscription_is_mail_package_active').is(':checked')
    selected_options.push 'period_duration', 'number_of_journals', 'pre_assignment', 'stamp'
    $('#subscription_is_annual_package_active').attr('disabled', 'disabled')
  if $('#subscription_is_scan_box_package_active').is(':checked')
    selected_options.push 'period_duration', 'number_of_journals', 'pre_assignment', 'scanner'
    $('#subscription_is_annual_package_active').attr('disabled', 'disabled')
  if $('#subscription_is_retriever_package_active').is(':checked')
    selected_options.push 'period_duration', 'number_of_journals'
    $('#subscription_is_annual_package_active').attr('disabled', 'disabled')
  if $('#subscription_is_annual_package_active').is(':checked')
    selected_options.push 'number_of_journals'
    $('.package .light_package').attr('disabled', 'disabled')
  for option in options
    if selected_options.indexOf(option) != -1
      $('.'+option).show()
    else
      $('.'+option).hide()

update_warning = ->
  to_be_disabled_text = null
  if $('#subscription_period_duration').val() == '1'
    to_be_disabled_text = "(sera effectif le mois prochain)"
  else if $('#subscription_period_duration').val() == '3'
    to_be_disabled_text = "(sera effectif le trimestre prochain)"
  is_recently_created = $('form').data('is-recently-created') == true

  if $('#subscription_is_basic_package_active').is(':checked')
    $('.basic_package_disable_warning').remove()
  else if $('#subscription_is_basic_package_active').data('original-value') == 1 && !is_recently_created
    unless $('.basic_package_disable_warning').length > 0
      $('#subscription_is_basic_package_active').parent('label').append('<b class="basic_package_disable_warning">'+to_be_disabled_text+'</b>')

  if $('#subscription_is_mail_package_active').is(':checked')
    $('.mail_package_disable_warning').remove()
  else if $('#subscription_is_mail_package_active').data('original-value') == 1 && !is_recently_created
    unless $('.mail_package_disable_warning').length > 0
      $('#subscription_is_mail_package_active').parent('label').append('<b class="mail_package_disable_warning">'+to_be_disabled_text+'</b>')

  if $('#subscription_is_scan_box_package_active').is(':checked')
    $('.scan_box_package_disable_warning').remove()
  else if $('#subscription_is_scan_box_package_active').data('original-value') == 1 && !is_recently_created
    unless $('.scan_box_package_disable_warning').length > 0
      $('#subscription_is_scan_box_package_active').parent('label').append('<b class="scan_box_package_disable_warning">'+to_be_disabled_text+'</b>')

  if $('#subscription_is_retriever_package_active').is(':checked')
    $('.retriever_package_disable_warning').remove()
    if !$('#subscription_is_basic_package_active').is(':checked') && !$('#subscription_is_mail_package_active').is(':checked') && !$('#subscription_is_scan_box_package_active').is(':checked')
      $('.retriever_package_warning').show()
    else
      $('.retriever_package_warning').hide()
  else if $('#subscription_is_retriever_package_active').data('original-value') == 1 && !is_recently_created
    $('.retriever_package_warning').hide()
    unless $('.retriever_package_disable_warning').length > 0
      $('#subscription_is_retriever_package_active').parent('label').append('<b class="retriever_package_disable_warning">'+to_be_disabled_text+'</b>')

  if $('#subscription_is_pre_assignment_active_true').is(':checked')
    $('.pre_assignment_disable_warning').remove()
  else if $('#subscription_is_pre_assignment_active_true').data('original-value') == 1 && !is_recently_created
    unless $('.pre_assignment_disable_warning').length > 0
      $('#subscription_is_pre_assignment_active_false').parent('label').parent('.choice').after('<div class="pre_assignment_disable_warning"><b>'+to_be_disabled_text+'</b></div>')

  if $('#subscription_is_stamp_active_true').is(':checked')
    $('.stamp_disable_warning').remove()
  else if $('#subscription_is_stamp_active_true').data('original-value') == 1 && !is_recently_created
    unless $('.stamp_disable_warning').length > 0
      $('#subscription_is_stamp_active_false').parent('label').parent('.choice').after('<div class="stamp_disable_warning"><b>'+to_be_disabled_text+'</b></div>')

  if $('#subscription_is_blank_page_remover_active_true').is(':checked')
    $('.blank_page_remover_disable_warning').remove()
  else if $('#subscription_is_blank_page_remover_active_true').data('original-value') == 1 && !is_recently_created
    unless $('.blank_page_remover_disable_warning').length > 0
      $('#subscription_is_blank_page_remover_active_false').parent('label').parent('.choice').after('<div class="blank_page_remover_disable_warning"><b>'+to_be_disabled_text+'</b></div>')

update_price = ->
  price_list = {
    'subscription':        [10,   30,   null],
    'pre_assignment':      [9,    15,   null],
    'return_paper':        [10,   10,   null],
    'stamp':               [5,    5,    null],
    'blank_page_deletion': [1,    1,    null],
    'retriever':           [5,    15,   null],
    'annual_subscription': [null, null, 199]
  }
  selected_options = []
  price = 0
  period_type = 0

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

    options = []
    if $('#subscription_is_basic_package_active').is(':checked')
      options.push 'subscription', 'pre_assignment'
    if $('#subscription_is_mail_package_active').is(':checked')
      options.push 'subscription', 'pre_assignment', 'return_paper', 'stamp'
    if $('#subscription_is_scan_box_package_active').is(':checked')
      options.push 'subscription', 'pre_assignment', 'blank_page_deletion'
    if $('#subscription_is_retriever_package_active').is(':checked')
      options.push 'retriever'
    options = _.uniq(options)

    for option in options
      if option == 'stamp'
        if $('#subscription_is_stamp_active_true').is(':checked')
          selected_options.push 'stamp'
      else if option == 'pre_assignment'
        if $('#subscription_is_pre_assignment_active_true').is(':checked')
          selected_options.push 'pre_assignment'
      else if option == 'blank_page_deletion'
        if $('#subscription_is_blank_page_remover_active_true').is(':checked')
          selected_options.push 'blank_page_deletion'
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

jQuery ->
  if $('#subscriptions.edit, #organization_subscriptions.edit').length > 0
    update_form()
    update_warning()
    update_price()

    $('.package input').on 'change', ->
      update_form()

    $('input, select').on 'change', ->
      update_warning()
      update_price()

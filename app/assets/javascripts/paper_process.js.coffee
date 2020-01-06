year  = -> $('#date_year').val()
month = -> $('#date_month').val()
day   = -> $('#date_day').val()

create_return_labels = ->
  $.ajax
    url: "/scans/return_labels/#{year()}/#{month()}/#{day()}",
    data: $('#returnLabelsForm .form').serialize(),
    datatype: 'json',
    type: 'POST',
    success: (data) ->
      $('#returnLabelsForm input[type=submit]').removeClass('disabled')
      $('#returnLabelsDialog iframe').attr('src', '/scans/return_labels')

new_return_labels = ->
  $('#returnLabelsForm').html('')
  $('#returnLabelsDialog iframe').attr('src', '')
  $.ajax
    url: "/scans/return_labels/new/#{year()}/#{month()}/#{day()}",
    data: {},
    datatype: 'json',
    type: 'GET',
    success: (data) ->
      $('#returnLabelsForm').html(data)
      $('#returnLabelsForm input[type=submit]').click (e) ->
        e.preventDefault()
        unless $(this).hasClass('disabled')
          $(this).addClass('disabled')
          create_return_labels()

isKitFormValid = (customer_codes) ->
  good = true
  good = false if $('#paper_process_tracking_number').val().length < 13
  good = false if $.inArray($('#paper_process_customer_code').val(), customer_codes) == -1
  good = false if parseInt($('#paper_process_journals_count').val()) <= 0
  good = false if parseInt($('#paper_process_periods_count').val()) <= 0
  good = false if parseInt($('#paper_process_order_id').val()) <= 0
  good

jQuery ->
  base = 'kits'     if $('#kits').length > 0
  base = 'receipts' if $('#receipts').length > 0
  base = 'scans'    if $('#scans').length > 0
  base = 'returns'  if $('#returns').length > 0
  $('.date select').on 'change', ->
    window.location.href = "/#{base}/#{year()}/#{month()}/#{day()}"

  $('#paper_process_tracking_number').keyup ->
    if $(this).val().length == 13
      $('#paper_process_customer_code').focus()

  if $('#kits, #receipts, #returns').length > 0
    customer_codes = $('#kits, #receipts, #returns').data('codes')
    $('#paper_process_customer_code').keyup ->
      if $.inArray($(this).val(), customer_codes) >= 0
        if $('#kits').length > 0
          $('#paper_process_journals_count').focus()
        else if $('#receipts').length > 0
          $('#new_paper_process').submit()
        else if $('#returns').length > 0
          $('#paper_process_letter_type').focus()

    if $('#kits').length > 0
      $(window).keydown (event) ->
        if (event.keyCode == 13) && (isKitFormValid(customer_codes) == false)
          event.preventDefault()
          false

  $('#paper_process_letter_type').keyup ->
    val = $(this).val()
    if val == '5' || val == '500'
      $(this).val('500')
      $('#new_paper_process').submit()
    else if val == '1' || val == '1000'
      $(this).val('1000')
      $('#new_paper_process').submit()
    else if val == '3' || val == '3000'
      $(this).val('3000')
      $('#new_paper_process').submit()

  $('#returnLabelsDialog').on 'shown.bs.modal', ->
    new_return_labels()

jQuery ->
  $('#paper_process_tracking_number').keyup ->
    if $(this).val().length == 13
      $('#paper_process_customer_code').focus()

  customer_codes = $('#kits').data('codes')
  $('#paper_process_customer_code').keyup ->
    if $.inArray($(this).val(), customer_codes) >= 0
      $('#paper_process_journals_count').focus()

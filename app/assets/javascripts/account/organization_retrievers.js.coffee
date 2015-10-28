jQuery ->
  if $('#bank_accounts.select, #retrieved_documents.select').length > 0
    $('#master_checkbox').change ->
      if $(this).is(':checked')
        $('.checkbox').attr('checked', true);
      else
        $('.checkbox').attr('checked', false);

jQuery ->
  $('a.do-showInvoice').on 'click', (e) ->
    e.preventDefault()
    $invoiceDialog = $('#showInvoice')
    $invoiceDialog.find('h3').text($(this).attr('title'))
    $invoiceDialog.find("iframe").attr('src',$(this).attr('href'))
    $invoiceDialog.modal()

  if $('#invoice_setting_user_code').length > 0
    file_upload_params = $('#data-invoice-upload').data('params')
    file_upload_update_fields = (code) ->
      account_book_types = file_upload_params[code]['journals']
      journals_compta_processable = file_upload_params[code]['journals_compta_processable'] or []
      content = ''
      i = 0
      while i < account_book_types.length
        name = account_book_types[i].split(' ')[0].trim()
        compta_processable = if journals_compta_processable.includes(name) then '1' else '0'
        content = content + '<option compta-processable=' + compta_processable + ' value=' + name + '>' + account_book_types[i] + '</option>'
        i++
      $('#invoice_setting_journal_code').html content

  $('#invoice_setting_user_code').on 'change', ->
    if $(this).val() != ''
      file_upload_update_fields $(this).val()
      $('#invoice_setting_journal_code').val()
      $('#invoice_setting_journal_code').change()
    else
      $('#invoice_setting_journal_code').html ''



  #invoice setting edit
  $('#invoice-setting-table tr td #invoice-setting-edit').on 'click', (e) ->
    e.preventDefault()
    code = $(this).attr("code")
    journal = $(this).attr("journal")
    id = $(this).attr("invoice_setting_id")

    $("#invoice_setting_user_code option:contains("+code+")")
      .removeAttr('selected')
      .val(code)
      .prop("selected",true)
    $("#invoice_setting_user_code").change()

    $("#invoice_setting_journal_code option:contains("+journal+")")
      .removeAttr('selected')
      .val(journal)
      .prop("selected",true)
    $("#invoice_setting_journal_code").change()
    
    $("input:hidden[name="+'"invoice_setting[id]"'+"]").val(id)

    $("#insert-invoice-setting").val('Modifier')

  #invoice_setting_synchronize
  $('#invoice-setting-table tr td #invoice-setting-synchronize').on 'click', (e) ->
    e.preventDefault()
    user_info = $(this).attr("user_info")
    id = $(this).attr("invoice_setting_id")

    $("input:hidden[name="+'"invoice_setting_id"'+"]").val(id)
    $("#synchronize_user_info").text(user_info)
    #$('#invoice_config_dialog').modal('hide')
    $('#invoice_config_dialog').fadeOut 500, ->
      $('#invoice_config_dialog').modal 'hide'
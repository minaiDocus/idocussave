jQuery ->
  $('a.do-showInvoice').click (e) ->
    e.preventDefault()
    $invoiceDialog = $('#showInvoice')
    $invoiceDialog.find('h3').text($(this).attr('title'))
    $invoiceDialog.find("iframe").attr('src',$(this).attr('href'))
    $invoiceDialog.modal()

  $('.select-date.requested_at').change (e) ->
    number = $(this).parents('tr').attr('id').split('_')[1]
    data = { invoice: { requested_at: $(this).val() } }
    $.ajax
      url: "/admin/invoices/#{number}.json"
      data: data
      datatype: 'json'
      type: 'PATCH'

  $('.select-date.received_at').change (e) ->
    number = $(this).parents('tr').attr('id').split('_')[1]
    data = { invoice: { received_at: $(this).val() } }
    $.ajax
      url: "/admin/invoices/#{number}.json"
      data: data
      datatype: 'json'
      type: 'PATCH'

  $("#check_all").change (e) ->
    $(".invoices").prop('checked', $(this).prop('checked'))

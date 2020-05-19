jQuery ->
  current_year = new Date().getFullYear()
  url_location = window.location.href
  current_year = url_location.split('reporting/')[1]

  $('#reporting .organization_list tr.row_organizations').each (e)->
    organization_id = $(this).attr('id').split('-')[1]

    $.ajax(
      type: 'GET',
      data: { organization_id: organization_id, year: current_year }
      url: '/admin/reporting/row_organization',
      contentType: 'application/json',
      async: false,
      ).success (response) ->
        $("#reporting .organization_list tr#row-" + organization_id).html(response)

  footer_table_data = [[0,0,0,0,0,0,0,0,0,0,0,0], [0,0,0,0,0,0,0,0,0,0,0,0], [0,0,0,0,0,0,0,0,0,0,0,0]]
  with_params_year  = $('input[type=hidden].total-span-3').val()

  $('#reporting .organization_list tr.row_organizations').each ->
    $('td.months_list', this).each (index, val) ->
      total_0 = $(val).find('input[type=hidden].total-span-0').val()
      total_1 = $(val).find('input[type=hidden].total-span-1').val()
      total_2 = $(val).find('input[type=hidden].total-span-2').val()

      if !(total_0 == 'undefined' || total_0 == undefined || total_0 == '' || total_0 == null) && parseInt(total_0) >= 0
        footer_table_data[0][index] += parseInt(total_0)
      if !(total_1 == 'undefined' || total_1 == undefined || total_1 == '' || total_1 == null) && parseInt(total_1) >= 0
        footer_table_data[1][index] += parseInt(total_1)
      if !(total_2 == 'undefined' || total_2 == undefined || total_2 == '' || total_2 == null) && parseInt(total_2) >= 0
        footer_table_data[2][index] += parseInt(total_2)
  
  $.ajax(
    type: 'POST',
    data: JSON.stringify({ total: footer_table_data, year: with_params_year })
    url: '/admin/reporting/total_footer',
    contentType: 'application/json',
    async: false,
    ).success (response) ->
      $("#reporting .organization_list tr#total_footer").html(response)

  $('#reporting .download-export_xls').on 'click', (e) ->
    e.preventDefault()
    $('#reporting #show-export-xls-link').append('<span class="alert alert-info show-notify-content">Téléchargement encours ...<span/>')
    $('#reporting #show-export-xls-link .show-notify-content').hide('fade',5000)
    class_list = $(this).attr("class").split(/\s+/)
    ch_text    = 'Régénérer à nouveau le fichier '
    $.each class_list, (index, item) ->
      if item == 'simplified_xls'
        ch_text = 'Régénérer à nouveau XLS Simplifié '
    $(this).text(ch_text)
    $(this).append('<img alt="Export xls" style="position:relative;top:-2px;" src="/assets/application/icon-xls.png">')
    $('#reporting #show-export-xls-link .download-link, #reporting #show-export-xls-link .show-content').remove()

    raw_element = $(this).attr('href')
    year = raw_element.split('.xls')[0]
    year = year.split('reporting/')[1]
    simplified = raw_element.split('simplified=')[1]

    _url = year + '.xls'
    filename = "reporting_iDocus_" + year + ".xls"
    if simplified != undefined
      _url = year + '?simplified=' + simplified
      filename = "reporting_simplifié_iDocus_" + year + ".xls"

    url = '/admin/reporting/' + _url

    request = new XMLHttpRequest
    request.open 'GET', url, true
    request.setRequestHeader 'Content-Type', 'application/x-www-form-urlencoded; charset=UTF-8'
    request.responseType = 'blob'

    request.send()

    request.onload = (e) ->
      if @status == 200
        blob = @response
        if window.navigator.msSaveOrOpenBlob
          window.navigator.msSaveBlob blob, filename
        else
          download_link = document.createElement('a')
          content_type_header = request.getResponseHeader('Content-Type')
          download_link.href = window.URL.createObjectURL(new Blob([ blob ], type: content_type_header))
          download_link.download = filename
          $('#reporting #show-export-xls-link').append('<span class="alert alert-success show-content">Votre fichier a été bien généré =><span/>')
          download_link.className = 'btn btn-link download-link'
          download_link.innerHTML = filename
          $('#reporting #show-export-xls-link').append download_link
          download_link.click()
          $('#reporting #show-export-xls-link').innerHTML = ''

    #request.send()

  $('a.do-showInvoice').click (e) ->
    e.preventDefault()
    $invoiceDialog = $('#showInvoice')
    $invoiceDialog.find('h3').text($(this).attr('title'))
    $invoiceDialog.find("iframe").attr('src',$(this).attr('href'))
    $invoiceDialog.modal()

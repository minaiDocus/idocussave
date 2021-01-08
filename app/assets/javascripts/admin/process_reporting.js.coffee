jQuery ->
  date = new Date()
  current_year = date.getFullYear()
  current_month = date.getMonth()
  url_location = window.location.href
  raw_element = url_location.split('reporting')[1]
  element = raw_element.split('/')
  current_year = element[1]
  current_month = element[2]
  elements_count = $('#process_reporting .organization_list tr.row_organizations').size()

  finalize_process = () ->
    result = [0,0,0,0,0,0,0,0,0,0,0]
    $('#process_reporting .organization_list tr.row_organizations').each ->
      $('td.raw_text', this).each (index, val) ->
        raw_text = $(this).text()
        if parseInt(raw_text) >= 0
          result[index] += parseInt(raw_text)

    $('#process_reporting .organization_list').append('<tr id="process_reporting-total-appended" style="opacity:1;"></tr>')
    $('#process_reporting .organization_list tr').last().append '<td>Total</td>'

    $(result).each ->
      $('#process_reporting .organization_list tr#process_reporting-total-appended').last().append '<td class="aligncenter"><b>' + this + '</b></td>'

  $('#process_reporting .organization_list tr.row_organizations').each (e)->
    organization_id = $(this).attr('id').split('-')[1]

    $.ajax(
      type: 'GET',
      data: { organization_id: organization_id, year: current_year, month: current_month }
      url: '/admin/process_reporting/process_reporting_table',
      contentType: 'application/json',
      ).success (response) ->
        $("#process_reporting .organization_list tr#row-" + organization_id).html(response)
        if(elements_count > 1)
          elements_count -= 1
        else
          window.setTimeout(finalize_process, 1000)

  
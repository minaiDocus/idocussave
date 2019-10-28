show_event = (id) ->
  $('#events .show').html('')
  $.ajax
    url: '/admin/events/' + id,
    data: '',
    datatype: 'html',
    type: 'GET'
    success: (data) ->
      $('#events .details.focusable').click()
      $('#events .show').html(data)      

jQuery ->
  $('#events .focusable').on 'click', (e) ->
    e.preventDefault()
    $('#events .focused').removeClass('focused')
    $(this).addClass('focused')

  $('tbody tr td.do-show').on 'click', (e) ->
    e.preventDefault()
    $tr = $(this).parent('tr')
    show_event($tr.data('id'))

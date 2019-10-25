show_event = (id) ->
  $('#events .show').html('')
  $.ajax
    url: '/admin/events/' + id,
    data: '',
    datatype: 'html',
    type: 'GET'
    success: (data) ->
      $('#events .show').html(data)      

jQuery ->
  $('tbody tr td.do-show').on 'click', (e) ->
    e.preventDefault()
    $tr = $(this).parent('tr')
    show_event($tr.data('id'))

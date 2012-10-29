active_csv_column_action = ->
  $('#edit_csv_outputter .remove_column').unbind('click')
  $('#edit_csv_outputter .remove_column').bind 'click', ->
    $(this).parents('li').remove()
    false

active_csv_global_action = ->
  $('#edit_csv_outputter .add_column').click ->
    $('#edit_csv_outputter .template li').clone().appendTo('#edit_csv_outputter .list')
    active_csv_column_action()
    false

  $('#edit_csv_outputter .remove_all_columns').click ->
    is_confirmed = confirm('Etes-vous sûr ?')
    if is_confirmed
      $('#edit_csv_outputter .list').html('')
    false

  $('#edit_csv_outputter .submit').click ->
    $(this).attr('disabled','disabled')
    put_csv_outputter()
    false

edit_csv_outputter = ->
  $.ajax
    url: '/admin/users/' + user_id + '/csv_outputter',
    data: '',
    datatype: 'json',
    type: 'GET'
    success: (data) ->
      $('#edit_csv_outputter .content').html(data)
      $('#edit_csv_outputter .content .list').sortable()
      active_csv_global_action()
      active_csv_column_action()

put_csv_outputter = ->
  data = {}
  data['user'] = {}
  data['user']['csv_outputter'] = {}
  directive = []
  $('#edit_csv_outputter .list li select option:selected').each (index,element) ->
    directive.push($(element).attr('value'))
  data['user']['csv_outputter']['directive'] = directive.join(';')
  data['_method'] = 'put'
  data['authenticity_token'] = $('#edit_csv_outputter input[name=authenticity_token]').attr('value')
  $.ajax
    url: '/admin/users/' + user_id,
    data: data,
    datatype: 'json',
    type: 'POST'
    success: (data) ->
      $('#edit_csv_outputter').modal('hide')

jQuery ->
  $('#edit_csv_outputter').on 'show', ->
    edit_csv_outputter()

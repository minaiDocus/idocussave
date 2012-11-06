initialize = ->
  $('#edit_csv_outputter option:selected').each (index,e) ->
    type = $(e).attr('value')
    if type == 'date' || type == 'deadline_date' || type == 'relevant_date'
      $(e).parents('li').find('input[name=format]').removeAttr('disabled')
    else
      $(this).parents('li').find('input[name=format]').val('')
      $(e).parents('li').find('input[name=format]').attr('disabled','disabled')

active_csv_field_action = ->
  $('#edit_csv_outputter .remove_field').unbind('click')
  $('#edit_csv_outputter .remove_field').bind 'click', ->
    $(this).parents('li').remove()
    false
  $('#edit_csv_outputter select').unbind('change')
  $('#edit_csv_outputter select').bind 'change', ->
    type = $(this).children('option:selected').attr('value')
    if type == 'date' || type == 'deadline_date' || type == 'relevant_date'
      $(this).parents('li').find('input[name=format]').removeAttr('disabled')
    else
      $(this).parents('li').find('input[name=format]').val('')
      $(this).parents('li').find('input[name=format]').attr('disabled','disabled')

active_csv_global_action = ->
  $('#edit_csv_outputter .add_field').click ->
    $('#edit_csv_outputter .template li.field').clone().appendTo('#edit_csv_outputter .list')
    active_csv_field_action()
    false

  $('#edit_csv_outputter .remove_all_fields').click ->
    is_confirmed = confirm('Etes-vous sûr ?')
    if is_confirmed
      $('#edit_csv_outputter .list').html('')
    false

  $('#edit_csv_outputter .submit').click ->
    $(this).attr('disabled','disabled')
    put_csv_outputter()
    false

edit_csv_outputter = ->
  $('#edit_csv_outputter .content').html('')
  $.ajax
    url: '/admin/users/' + user_id + '/csv_outputter',
    data: '',
    datatype: 'json',
    type: 'GET'
    success: (data) ->
      $('#edit_csv_outputter .content').html(data)
      $('#edit_csv_outputter .content .list').sortable()
      initialize()
      active_csv_global_action()
      active_csv_field_action()

put_csv_outputter = ->
  data = {}
  data['user'] = {}
  data['user']['csv_outputter'] = {}
  directive = []
  $('#edit_csv_outputter .list li').each (index,element) ->
    li = $(this)
    left_addition = li.find('input[name=left_addition]').val()
    right_addition = li.find('input[name=right_addition]').val()
    format = li.find('input[name=format]').val()
    field = li.find('option:selected').val()
    part = '{' + left_addition + '}' + field + '-' + format + '{' + right_addition + '}'
    directive.push(part)
  data['user']['csv_outputter']['directive'] = directive.join('|')
  data['_method'] = 'put'
  data['authenticity_token'] = $('#edit_csv_outputter input[name=authenticity_token]').val()

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
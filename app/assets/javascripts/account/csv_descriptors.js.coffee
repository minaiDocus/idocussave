initialize_csv_editor = ->
  $('#csv_descriptors.edit option:selected').each (index, e) ->
    type = $(e).attr('value')
    if type == 'date' || type == 'deadline_date' || type == 'period_date'
      $(e).parents('li').find('input[name=format]').removeAttr('disabled')
    else
      $(this).parents('li').find('input[name=format]').val('')
      $(e).parents('li').find('input[name=format]').attr('disabled','disabled')

activate_csv_field_action = ->
  $('#csv_descriptors.edit .remove_field').unbind('click')
  $('#csv_descriptors.edit .remove_field').bind 'click', ->
    $(this).parents('li').remove()
    false
  $('#csv_descriptors.edit select').unbind('change')
  $('#csv_descriptors.edit select').bind 'change', ->
    type = $(this).children('option:selected').attr('value')
    if type == 'date' || type == 'deadline_date' || type == 'period_date'
      $(this).parents('li').find('input[name=format]').removeAttr('disabled')
    else
      $(this).parents('li').find('input[name=format]').val('')
      $(this).parents('li').find('input[name=format]').attr('disabled','disabled')

activate_csv_global_action = ->
  $('#csv_descriptors.edit .add_field').click ->
    $('#csv_descriptors.edit .template li.field').clone().appendTo('#csv_descriptors.edit .list')
    activate_csv_field_action()
    false

  $('#csv_descriptors.edit .remove_all_fields').click ->
    is_confirmed = confirm('Etes-vous sûr ?')
    if is_confirmed
      $('#csv_descriptors.edit .list').html('')
    false

jQuery ->
  if $('#csv_descriptors.edit').length > 0
    $('#csv_descriptors.edit .list').sortable()
    initialize_csv_editor()
    activate_csv_global_action()
    activate_csv_field_action()

    $('#csv_descriptors.edit form').submit ->
      directive = []
      $('#csv_descriptors.edit .list li').each (index,element) ->
        li = $(this)
        left_addition = li.find('input[name=left_addition]').val()
        right_addition = li.find('input[name=right_addition]').val()
        format = li.find('input[name=format]').val()
        field = li.find('option:selected').val()
        part = '{' + left_addition + '}' + field + '-' + format + '{' + right_addition + '}'
        directive.push(part)
      $('#csv_descriptor_directive').val(directive.join('|'))
      true

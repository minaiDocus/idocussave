update_directive_input = (type, element) ->
  if type == 'date' || type == 'deadline_date' || type == 'period_date'
    element.parents('li').find('#text_format').hide()
    element.parents('li').find('#text_format').attr('disabled','disabled')
    element.parents('li').find('#select_format').show()
    element.parents('li').find('#select_format').removeAttr('disabled')
  else if type == 'other'
    element.parents('li').find('#select_format').hide()
    element.parents('li').find('#select_format').attr('disabled','disabled')
    element.parents('li').find('#text_format').show()
    element.parents('li').find('#text_format').removeAttr('disabled')
  else
    element.parents('li').find('#select_format').hide()
    element.parents('li').find('#select_format').attr('disabled','disabled')
    element.parents('li').find('#text_format').hide()
    element.parents('li').find('#text_format').attr('disabled','disabled')

initialize_csv_editor = ->
  $('#csv_descriptors.edit #select_directive option:selected').each (index, e) ->
    type = $(e).attr('value')
    update_directive_input(type, $(this))

activate_csv_field_action = ->
  $('#csv_descriptors.edit .remove_field').unbind('click')
  $('#csv_descriptors.edit .remove_field').bind 'click', ->
    $(this).parents('li').remove()
    false
  $('#csv_descriptors.edit #select_directive').unbind('change')
  $('#csv_descriptors.edit #select_directive').bind 'change', ->
    type = $(this).children('option:selected').attr('value')
    update_directive_input(type, $(this))

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
        field = li.find('option:selected').val()
        if field == 'date' || field == 'deadline_date' || field == 'period_date'
          part = field + '-' + li.find('#select_format').val()
        else if field == 'other'
          part = field + '-' + li.find('#text_format').val()
        else
          part = field
        directive.push(part)
      $('#csv_descriptor_directive').val(directive.join('|separator|'))
      true
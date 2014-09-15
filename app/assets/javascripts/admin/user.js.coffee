checkbox_event_handler = ->
  $('input[type=checkbox]').unbind 'click'
  $('input[type=checkbox]').bind 'click', ->
    url = '/admin/users/' + user_id
    hsh = {}
    value = -1
    if $(this).is(':checked')
      value = 1
    else
      value = 0
    hsh[$(this).attr('name')] = value
    $.ajax
      url: url,
      data: hsh,
      dataType: 'json',
      type: 'PUT'

jQuery ->
  checkbox_event_handler()

  $('.edit').click ->
    parent = $(this).parents('.static')
    prompt = parent.next('.prompt')

    value = parent.children('.value').text().trim()
    prompt.children('input').val(value)

    parent.addClass('hide')
    prompt.removeClass('hide')
    return false

  $('.ok').click ->
    prompt = $(this).parents('.prompt')
    original = prompt.prev('.static')

    value = prompt.children('input').val().trim()
    original.children('.value').text(value)

    url = '/admin/users/' + user_id
    hsh = {}
    hsh[prompt.children('input').attr('name')] = value
    $.ajax
      url: url,
      data: hsh,
      dataType: 'json',
      type: 'PUT'

    prompt.addClass('hide')
    original.removeClass('hide')
    return false

  $('.not_ok').click ->
    prompt = $(this).parents('.prompt')
    original = prompt.prev('.static')

    prompt.addClass('hide')
    original.removeClass('hide')
    return false

  $('.select-date').change ->
    data = {}
    value = $(this).val()
    format = /\d{4}-\d{1,2}-\d{1,2}/
    if value == "" || value.match(format)
      if value == ""
        data = { _method: 'PUT', user: { is_inactive: 0 } }
      else
        data = { _method: 'PUT', user: { is_inactive: 1, inactive_at: value } }

      $.ajax
        url: '/admin/users/' + user_id,
        data: data,
        datatype: 'json',
        type: 'POST'

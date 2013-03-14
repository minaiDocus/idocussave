get_addresses = ->
  $.ajax
    url: '/admin/users/' + user_id + '/addresses',
    data: '',
    datatype: 'html',
    type: 'GET',
    success: (data) ->
      $('#addresses').html(data)

post_addresses = ->
  data = $('.addresses.form').serialize().replace(new RegExp("put"),"post");
  $.ajax
    url: '/admin/users/' + user_id + '/addresses/update_multiple',
    data: data,
    datatype: 'json',
    type: 'POST',
    success: (data) ->
      $('#edit_addresses').modal('hide')
      get_addresses()

edit_addresses = ->
  $.ajax
    url: '/admin/users/' + user_id + '/addresses/edit_multiple',
    data: '',
    datatype: 'html',
    type: 'GET',
    success: (data) ->
      $('#edit_addresses .content').html(data)
      $('.addresses.form').submit ->
        post_addresses()
        return false

get_scan_subscription = ->
  $.ajax
    url: '/admin/users/' + user_id + '/scan_subscription',
    data: '',
    datatype: 'html',
    type: 'GET',
    success: (data) ->
      $('#scan_subscription').html(data)
      checkbox_event_handler()

edit_scan_subscription = ->
  $.ajax
    url: '/admin/users/' + user_id + '/scan_subscription/edit',
    data: '',
    datatype: 'html',
    type: 'GET',
    success: (data) ->
      $('#edit_scan_subscription .content').html(data)
      $('.scan_subscription.form').submit ->
        post_scan_subscription()
        return false

post_scan_subscription = ->
  $.ajax
    url: '/admin/users/' + user_id + '/scan_subscription',
    data: $('.scan_subscription.form').serialize() + '&_method=PUT',
    datatype: 'json',
    type: 'POST',
    success: (data) ->
      $('#edit_scan_subscription').modal('hide')
      get_scan_subscription()

get_account_book_types = ->
  $.ajax
    url: '/admin/users/' + user_id + '/account_book_types',
    data: '',
    datatype: 'html',
    type: 'GET',
    success: (data) ->
      $('#account_book_types').html(data)
      $('.remove_account_book_type').click ->
        id = $(this).parents('tr').attr('id')
        if confirm('Etes vous sûr ?')
          remove_account_book_type(id)
        return false
      $('.add_account_book_type').click ->
        id = $(this).parents('tr').attr('id')
        if confirm('Etes vous sûr ?')
          add_account_book_type(id)
        return false
      $('.accept_account_book_type').click ->
        id = $(this).parents('tr').attr('id')
        if confirm('Etes vous sûr ?')
          accept_account_book_type(id)
        return false

remove_account_book_type = (id) ->
  $.ajax
    url: '/admin/users/' + user_id + '/account_book_types/' + id + '/remove',
    data: { _method: 'DELETE' },
    datatype: 'json',
    type: 'POST',
    success: (data) ->
      get_account_book_types()

add_account_book_type = (id) ->
  $.ajax
    url: '/admin/users/' + user_id + '/account_book_types/' + id + '/add',
    data: { _method: 'PUT' },
    datatype: 'json',
    type: 'POST',
    success: (data) ->
      get_account_book_types()

accept_account_book_type = (id) ->
  $.ajax
    url: '/admin/users/' + user_id + '/account_book_types/' + id + '/accept',
    data: { _method: 'PUT' },
    datatype: 'json',
    type: 'POST',
    success: (data) ->
      get_account_book_types()

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

  get_addresses()

  $('#edit_addresses').on 'show', ->
    edit_addresses()

  get_scan_subscription()

  $('#edit_scan_subscription').on 'show', ->
    edit_scan_subscription()

  get_account_book_types()

  $('#new_account_book_type').on 'show', ->
    new_account_book_type()

  $('#user_is_prescriber').click ->
    get_account_book_types()
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

  $('#external_file_storage select.inplace').change ->
    name = $(this).attr('name')
    value = $(this).attr('value')
    data = { _method: 'PUT', }
    data[name] = value
    $.ajax
      url: "/admin/users/" + user_id,
      data: data,
      datatype: 'json',
      type: 'POST'
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
    url: '/admin/users/' + user_id + '/scan/subscription',
    data: '',
    datatype: 'html',
    type: 'GET',
    success: (data) ->
      $('#scan_subscription').html(data)

edit_scan_subscription = ->
  $.ajax
    url: '/admin/users/' + user_id + '/scan/subscription/edit',
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
    url: '/admin/users/' + user_id + '/scan/subscription',
    data: $('.scan_subscription.form').serialize() + '&_method=PUT',
    datatype: 'json',
    type: 'POST',
    success: (data) ->
      $('#edit_scan_subscription').modal('hide')
      get_scan_subscription()

get_reminder_emails = ->
  $.ajax
    url: '/admin/users/' + user_id + '/reminder_emails',
    data: '',
    datatype: 'html',
    type: 'GET',
    success: (data) ->
      $('#reminder_emails').html(data)
      $('#user_is_reminder_email_active').change ->
        is_ok = confirm 'Etes vous sûr ?'
        if !is_ok
          $(this).attr('checked',!$(this).is(':checked'))
        else
          form_data = $('#user_reminder_email_options').serialize()
          $.ajax
            url: '/admin/users/' + user_id,
            data: form_data,
            datatype: 'json',
            type: 'POST'


edit_reminder_emails = ->
  $.ajax
    url: '/admin/users/' + user_id + '/reminder_emails/edit_multiple',
    data: '',
    datatype: 'html',
    type: 'GET',
    success: (data) ->
      $('#edit_reminder_emails .content').html(data)
      $('.reminder_emails.form').submit ->
        post_reminder_emails()
        return false

post_reminder_emails = ->
  data = $('.reminder_emails.form').serialize().replace(new RegExp("put"),"post");
  $.ajax
    url: '/admin/users/' + user_id + '/reminder_emails/update_multiple',
    data: data,
    datatype: 'json',
    type: 'POST',
    success: (data) ->
      $('#edit_reminder_emails').modal('hide')
      get_reminder_emails()

get_file_sending_kit = ->
  $.ajax
    url: '/admin/users/' + user_id + '/file_sending_kit',
    data: '',
    datatype: 'html',
    type: 'GET',
    success: (data) ->
      $('#file_sending_kit').html(data)

edit_file_sending_kit = ->
  $.ajax
    url: '/admin/users/' + user_id + '/file_sending_kit/edit',
    data: '',
    datatype: 'html',
    type: 'GET',
    success: (data) ->
      $('#edit_file_sending_kit .content').html(data)
      $('.file_sending_kit.form').submit ->
        post_file_sending_kit()
        return false

post_file_sending_kit = ->
  $.ajax
    url: '/admin/users/' + user_id + '/file_sending_kit',
    data: $('.file_sending_kit.form').serialize(),
    datatype: 'json',
    type: 'POST',
    success: (data) ->
      $('#edit_file_sending_kit').modal('hide')

select_file_sending_kit = ->
  $.ajax
    url: '/admin/users/' + user_id + '/file_sending_kit/select',
    data: '',
    datatype: 'html',
    type: 'GET',
    success: (data) ->
      $('#select_file_sending_kit .content').html(data)
      $('.file_sending_kit.form').submit ->
        generate_file_sending_kit()
        return false

generate_file_sending_kit = ->
  data = $('.file_sending_kit.form').serialize.replace(new RegExp("put"),"post")
  $.ajax
    url: '/admin/users/' + user_id + '/file_sending_kit/generate',
    data: data,
    datatype: 'json',
    type: 'POST',
    success: (data) ->
      $('#select_file_sending_kit').modal('hide')

get_account_book_types = ->
  $.ajax
    url: '/admin/users/' + user_id + '/account_book_types',
    data: '',
    datatype: 'html',
    type: 'GET',
    success: (data) ->
      $('#account_book_types').html(data)
      $('.edit_account_book_type').click ->
        id = $(this).parents('tr').attr('id')
        edit_account_book_type(id)
        return false
      $('.destroy_account_book_type').click ->
        id = $(this).parents('tr').attr('id')
        if confirm('Etes vous sûr ?')
          destroy_account_book_type(id)
        return false

new_account_book_type = ->
  $.ajax
    url: '/admin/users/' + user_id + '/account_book_types/new',
    data: '',
    datatype: 'html',
    type: 'GET',
    success: (data) ->
      $('#new_account_book_type .content').html(data)
      $('.account_book_type.form').submit ->
        create_account_book_type()
        return false

create_account_book_type = ->
  $.ajax
    url: '/admin/users/' + user_id + '/account_book_types.json',
    data: $('#new_account_book_type .form').serialize(),
    datatype: 'json',
    type: 'POST',
    success: (data) ->
      $('#new_account_book_type').modal('hide')
      get_account_book_types()

edit_account_book_type = (id) ->
  $('#edit_account_book_type').modal('show')
  $.ajax
    url: '/admin/users/' + user_id + '/account_book_types/' + id + '/edit',
    data: '',
    datatype: 'html',
    type: 'GET',
    success: (data) ->
      $('#edit_account_book_type .content').html(data)
      $('.account_book_type.form').submit ->
        update_account_book_type(id)
        return false

update_account_book_type = (id) ->
  $.ajax
    url: '/admin/users/' + user_id + '/account_book_types/' + id + '.json',
    data: $('#edit_account_book_type .form').serialize(),
    datatype: 'json',
    type: 'POST',
    success: (data) ->
      $('#edit_account_book_type').modal('hide')
      get_account_book_types()

destroy_account_book_type = (id) ->
  $.ajax
    url: '/admin/users/' + user_id + '/account_book_types/' + id,
    data: { _method: 'DELETE' },
    datatype: 'json',
    type: 'POST',
    success: (data) ->
      get_account_book_types()

update_user_clients = ->
  client_ids = $('#user_client_ids').val()
  $.ajax
    url: '/admin/users/' + user_id,
    data: { _method: 'PUT', 'user[client_ids]': client_ids },
    datatype: 'json',
    type: 'POST'

get_propagate_stamp_name = ->
  $.ajax
    url: '/admin/users/' + user_id + '/propagate_stamp_name',
    data: '',
    datatype: 'json',
    type: 'GET'
  
toggle_prescriber_options = ->
  if $('#user_is_prescriber').is(':checked')
    $('#prescriber_options table').removeClass('hide')
    $('#stamp_propagation').show()
  else
    $('#prescriber_options table').addClass('hide')
    $('#stamp_propagation').hide()

jQuery ->
  $('input[type=checkbox]').click ->
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

  get_reminder_emails()

  $('#edit_reminder_emails').on 'show', ->
    edit_reminder_emails()

  get_file_sending_kit()

  $('#edit_file_sending_kit').on 'show', ->
    edit_file_sending_kit()

  $('#select_file_sending_kit').on 'show', ->
    select_file_sending_kit()

  get_account_book_types()

  $('#new_account_book_type').on 'show', ->
    new_account_book_type()

  $('#user_client_ids').tokenInput "/admin/users/search_by_code.json",
    theme: "facebook",
    prePopulate: clients,
    searchDelay: 500,
    minChars: 1,
    preventDuplicates: true,
    hintText: "Tapez un code client à rechercher",
    noResultsText: "Aucun résultat",
    searchingText: "Recherche en cours...",
    onAdd: (item) ->
      update_user_clients()
    ,
    onDelete: (item) ->
      update_user_clients()

  toggle_prescriber_options()

  $('#user_is_prescriber').click ->
    toggle_prescriber_options()
    get_reminder_emails()
    get_file_sending_kit()
    get_account_book_types()
    get_propagate_stamp_name()

  $('#stamp_propagation').click ->
    value = confirm('Voulez vous vraiment propager les changements vers tout les clients ?')
    if(value)
      get_propagate_stamp_name()
    return false

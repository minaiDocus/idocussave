get_reminder_emails = ->
  $.ajax
    url: '/admin/organizations/' + organization_id + '/reminder_emails',
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
    url: '/admin/organizations/' + organization_id + '/reminder_emails/edit_multiple',
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
    url: '/admin/organizations/' + organization_id + '/reminder_emails/update_multiple',
    data: data,
    datatype: 'json',
    type: 'POST',
    success: (data) ->
      $('#edit_reminder_emails').modal('hide')
      get_reminder_emails()

get_file_sending_kit = ->
  $.ajax
    url: '/admin/organizations/' + organization_id  + '/file_sending_kit',
    data: '',
    datatype: 'html',
    type: 'GET',
    success: (data) ->
      $('#file_sending_kit').html(data)

edit_file_sending_kit = ->
  $.ajax
    url: '/admin/organizations/' + organization_id  + '/file_sending_kit/edit',
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
    url: '/admin/organizations/' + organization_id  + '/file_sending_kit',
    data: $('.file_sending_kit.form').serialize(),
    datatype: 'json',
    type: 'POST',
    success: (data) ->
      $('#edit_file_sending_kit').modal('hide')

select_file_sending_kit = ->
  $.ajax
    url: '/admin/organizations/' + organization_id  + '/file_sending_kit/select',
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
    url: '/admin/organizations/' + organization_id  + '/file_sending_kit/generate',
    data: data,
    datatype: 'json',
    type: 'POST',
    success: (data) ->
      $('#select_file_sending_kit').modal('hide')

get_ibiza = ->
  $.ajax
    url: '/admin/organizations/' + organization_id + '/ibiza',
    data: '',
    datatype: 'html',
    type: 'GET',
    success: (data) ->
      $('#ibiza_options').html(data)

get_scan_subscription = ->
  $.ajax
    url: '/admin/organizations/' + organization_id + '/subscription',
    data: '',
    datatype: 'html',
    type: 'GET',
    success: (data) ->
      $('#scan_subscription').html(data)

edit_scan_subscription = ->
  $.ajax
    url: '/admin/organizations/' + organization_id + '/subscription/edit',
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
    url: '/admin/organizations/' + organization_id + '/subscription',
    data: $('.scan_subscription.form').serialize() + '&_method=PUT',
    datatype: 'json',
    type: 'POST',
    success: (data) ->
      $('#edit_scan_subscription').modal('hide')
      get_scan_subscription()

get_account_book_types = ->
  $.ajax
    url: '/admin/organizations/' + organization_id + '/journals',
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

new_account_book_type = ->
  $.ajax
    url: '/admin/organizations/' + organization_id + '/journals/new',
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
    url: '/admin/organizations/' + organization_id + '/journals.json',
    data: $('#new_account_book_type .form').serialize(),
    datatype: 'json',
    type: 'POST',
    success: (data) ->
      $('#new_account_book_type').modal('hide')
      get_account_book_types()

edit_account_book_type = (id) ->
  $('#edit_account_book_type').modal('show')
  $.ajax
    url: '/admin/organizations/' + organization_id + '/journals/' + id + '/edit',
    data: '',
    datatype: 'html',
    type: 'GET',
    success: (data) ->
      $('#edit_account_book_type .content').html(data)
      $('.assign_value').click ->
        value = $(this).next('span').text()
        $($(this).attr('href')).attr('value',value)
        return false
      $('.account_book_type.form').submit ->
        update_account_book_type(id)
        return false

update_account_book_type = (id) ->
  $.ajax
    url: '/admin/organizations/' + organization_id + '/journals/' + id + '.json',
    data: $('#edit_account_book_type .form').serialize(),
    datatype: 'json',
    type: 'POST',
    success: (data) ->
      $('#edit_account_book_type').modal('hide')
      get_account_book_types()

destroy_account_book_type = (id) ->
  $.ajax
    url: '/admin/organizations/' + organization_id + '/journals/' + id,
    data: { _method: 'DELETE' },
    datatype: 'json',
    type: 'POST',
    success: (data) ->
      get_account_book_types()

accept_account_book_type = (id) ->
  $.ajax
    url: '/admin/organizations/' + organization_id + '/journals/' + id + '/accept',
    data: { _method: 'PUT' },
    datatype: 'json',
    type: 'POST',
    success: (data) ->
      get_account_book_types()

initialize_csv_editor = ->
  $('#edit_csv_outputter option:selected').each (index,e) ->
    type = $(e).attr('value')
    if type == 'date' || type == 'deadline_date' || type == 'period_date'
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
    if type == 'date' || type == 'deadline_date' || type == 'period_date'
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
    url: '/admin/organizations/' + organization_id + '/csv_outputter',
    data: '',
    datatype: 'json',
    type: 'GET'
    success: (data) ->
      $('#edit_csv_outputter .content').html(data)
      $('#edit_csv_outputter .content .list').sortable()
      initialize_csv_editor()
      active_csv_global_action()
      active_csv_field_action()

put_csv_outputter = ->
  data = {}
  data['organization'] = {}
  data['organization']['csv_outputter'] = {}
  directive = []
  $('#edit_csv_outputter .list li').each (index,element) ->
    li = $(this)
    left_addition = li.find('input[name=left_addition]').val()
    right_addition = li.find('input[name=right_addition]').val()
    format = li.find('input[name=format]').val()
    field = li.find('option:selected').val()
    part = '{' + left_addition + '}' + field + '-' + format + '{' + right_addition + '}'
    directive.push(part)
  data['organization']['csv_outputter']['directive'] = directive.join('|')
  data['organization']['csv_outputter']['comma_as_number_separator'] = $('#organization_csv_outputter_comma_as_number_separator').is(':checked')
  data['_method'] = 'put'
  data['authenticity_token'] = $('#edit_csv_outputter input[name=authenticity_token]').val()

  $.ajax
    url: '/admin/organizations/' + organization_id,
    data: data,
    datatype: 'json',
    type: 'POST'
    success: (data) ->
      $('#edit_csv_outputter').modal('hide')

propagate_csv_outputter = ->
  $('#propagate_csv_outputter .content').html('')
  $.ajax
    url: '/admin/organizations/' + organization_id + '/csv_outputter/select_propagation_options',
    data: '',
    datatype: 'json',
    type: 'GET'
    success: (data) ->
      $('#propagate_csv_outputter .content').html(data)

jQuery ->
  window.organization_id = $('#organization').data('slug')

  $('#organization_leader_id').tokenInput "/admin/users/search_by_code.json?full_info=true",
    theme: "facebook",
    searchDelay: 500,
    minChars: 1,
    tokenLimit: 1,
    preventDuplicates: true,
    prePopulate: $('#doc_group_leader_id').data('pre'),
    hintText: "Tapez un code utilisateur à rechercher",
    noResultsText: "Aucun résultat",
    searchingText: "Recherche en cours..."

  $('#organization_member_tokens').tokenInput "/admin/users/search_by_code.json",
    theme: "facebook",
    searchDelay: 500,
    minChars: 1,
    preventDuplicates: true,
    prePopulate: $('#doc_group_member_tokens').data('pre'),
    hintText: "Tapez un code utilisateur à rechercher",
    noResultsText: "Aucun résultat",
    searchingText: "Recherche en cours..."

  if organization_id != undefined
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

    get_ibiza()

    get_account_book_types()

    $('#new_account_book_type').on 'show', ->
      new_account_book_type()

    $('#edit_csv_outputter').on 'show', ->
      edit_csv_outputter()

    $('#propagate_csv_outputter').on 'show', ->
      propagate_csv_outputter()
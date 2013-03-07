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
      checkbox_event_handler()

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
jQuery ->
  if $('#customer.edit_period_options').length > 0
    $('#user_authd_prev_period').on 'change', ->
      $('#user_auth_prev_period_until_day').val(0)

    $('#user_auth_prev_period_until_day').on 'change', ->
      $('#user_authd_prev_period').val(1)

  if $('#customer.edit.ibiza').length > 0
    $('#user_ibiza_id').after('<div class="feedback"></div>')
    $.ajax
      url: $('#user_ibiza_id').data('users-list-url'),
      data: '',
      dataType: 'json',
      type: 'GET',
      success: (data) ->
        original_value = $('#user_ibiza_id').data('original-value') || ''
        for d in data
          option_html = ''
          if original_value.length > 0 && original_value == d['id']
            option_html = '<option value="'+d['id']+'" selected="selected">'+d['name']+'</option>'
          else
            option_html = '<option value="'+d['id']+'">'+d['name']+'</option>'
          $('#user_ibiza_id').append(option_html)
        $('#user_ibiza_id').show()
        $('#user_ibiza_id').chosen
          search_contains: true,
          no_results_text: 'Aucun résultat correspondant à'
        $('.feedback').remove()
        $('input[type=submit]').removeAttr('disabled')

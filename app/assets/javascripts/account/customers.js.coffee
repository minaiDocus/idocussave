jQuery ->
  $('#user_authd_prev_period').on 'change', ->
    if $(this).val() != '1'
      $('#user_auth_prev_period_until_day').val(0)
      $('#user_auth_prev_period_until_month').val(0)

  $('#user_auth_prev_period_until_day').on 'change', ->
    $('#user_authd_prev_period').val(1)

  $('#user_auth_prev_period_until_month').on 'change', ->
    $('#user_authd_prev_period').val(1)

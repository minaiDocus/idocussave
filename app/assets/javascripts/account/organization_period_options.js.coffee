jQuery ->
  $('#organization_authd_prev_period').on 'change', ->
    $('#organization_auth_prev_period_until_day').val(0)

  $('#organization_auth_prev_period_until_day').on 'change', ->
    $('#organization_authd_prev_period').val(1)

#//= require jquery_nested_form

jQuery ->
  $('#organization_authd_prev_period').on 'change', ->
    if $(this).val() != '1'
      $('#organization_auth_prev_period_until_day').val(0)
      $('#organization_auth_prev_period_until_month').val(0)

  $('#organization_auth_prev_period_until_day').on 'change', ->
    $('#organization_authd_prev_period').val(1)

  $('#organization_auth_prev_period_until_month').on 'change', ->
    $('#organization_authd_prev_period').val(1)

check_disabled_options = ->
  $('#subscription_package_form input:checkbox').each(->
    if $(this).attr('disabled') == 'disabled'
      hidden = $("#subscription_package_form input:hidden[name='"+$(this).attr('name')+"']")
      if hidden
        hidden.val($(this).is(':checked'))
      else
        $(this).after('<input type="hidden" name="'+$(this).attr('name')+'" value="'+$(this).is(':checked')+'">')
  )

refresh_softwares = (obj)->
  if(obj.attr('id') == 'softwares_is_ibiza_used' && obj.is(':checked'))
    $('#softwares_is_exact_online_used').removeAttr('checked')
  else if(obj.attr('id') == 'softwares_is_exact_online_used' && obj.is(':checked'))
    $('#softwares_is_ibiza_used').removeAttr('checked')

jQuery ->
  if $('#organization_subscriptions.edit').length > 0
    $('#subscriptions #admin_options_button').on 'click', ->
      if $('#subscriptions .admin_options').is(':visible')
        $('#subscriptions .admin_options').fadeOut('fast')
      else
        $('#subscriptions .admin_options').fadeIn('fast')

    $('input, select').on 'change', ->
      update_warning()

    $('#subscription_package_form').on 'submit', ->
      check_disabled_options()

    $('.softwares_setting').on 'click', ->
      refresh_softwares($(this))


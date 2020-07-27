update_warning = ->
  is_recently_created = $('form').data('is-recently-created') == true
  $('.notify-warning').addClass('hide')
  $('.to_disable_later').removeClass('to_disable_later')

  if !$('#subscription_subscription_option_is_idox_package_active').is(':checked') && $('#subscription_subscription_option_is_idox_package_active').data('original-value') == 1 && !is_recently_created
    $('#subscription_subscription_option_is_idox_package_active').parent('.form-check-inline').addClass('to_disable_later')

  if !$('#subscription_subscription_option_is_basic_package_active').is(':checked') && $('#subscription_subscription_option_is_basic_package_active').data('original-value') == 1 && !is_recently_created
    $('#subscription_subscription_option_is_basic_package_active').parent('.form-check-inline').addClass('to_disable_later')

  if !$('#subscription_subscription_option_is_micro_package_active').is(':checked') && $('#subscription_subscription_option_is_micro_package_active').data('original-value') == 1 && !is_recently_created
    $('#subscription_subscription_option_is_micro_package_active').parent('.form-check-inline').addClass('to_disable_later')

  if !$('#subscription_subscription_option_is_mini_package_active').is(':checked') && $('#subscription_subscription_option_is_mini_package_active').data('original-value') == 1 && !is_recently_created
    $('#subscription_subscription_option_is_mini_package_active').parent('.form-check-inline').addClass('to_disable_later')

  if $('#subscription_subscription_option_is_retriever_package_active').is(':checked') && $('#subscription_subscription_option_is_retriever_package_active').data('original-value') == 1 && !is_recently_created
    $('#subscription_subscription_option_is_retriever_package_active').parent('.form-check-inline').addClass('to_disable_later')
  if !$('#subscription_is_pre_assignment_active_true').is(':checked') && $('#subscription_is_pre_assignment_active_true').data('original-value') == 1 && !is_recently_created
    $('.subscription_is_pre_assignment_active_label').addClass('to_disable_later')

  $('.active_options').each (e) ->
    $(this).find('.option_checkbox').each (e) ->
      if !$(this).is(':checked') && $(this).data('original-value') == 1 && !is_recently_created
        $(this).parent('.form-check-inline').addClass('to_disable_later')

  if $('.to_disable_later').length > 0
    $('.notify-warning').removeClass('hide')

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
  $('#personalize_subscription_package_form input.subscription-package-form-change').on 'click', ->
    update_warning()
  update_warning()

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


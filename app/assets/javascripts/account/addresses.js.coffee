update_form = ->
  if $('#address_is_for_dematbox_shipping').is(':checked')
    $('label[for=address_company]').html('<abbr title="champ requis">*</abbr> Société')
    $('.dematbox_only').show()
  else
    $('label[for=address_company]').html('Société')
    $('.dematbox_only').hide()

jQuery ->
  if $('#address_is_for_dematbox_shipping').length > 0
    update_form()
    $('#address_is_for_dematbox_shipping').on 'change', ->
      update_form()

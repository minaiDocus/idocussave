jQuery ->
  $('#zoho_crm_organization_codes_').searchableOptionList({
    maxHeight: '150px'
    })
  $('.zoho_crm_synchronizer #zoho-crm-check-all').click (e) ->
    if $(this).is(':checked')
     $('#zoho_crm_organization_codes_').attr('disabled', 'disabled')
     $('#zoho_crm_organization_codes_').removeAttr('selected')
    else    
      $('#zoho_crm_organization_codes_').removeAttr('disabled')


jQuery ->
  $('.zoho-crm-form-synchronizer #zoho-crm-check-all').on 'click', (e) ->
    if $(this).is(':checked')
     $('#zoho_crm_organization_codes_ option').attr('selected', 'selected')
     $('#zoho_crm_organization_codes_').attr('disabled', 'disabled')
    else    
     $('#zoho_crm_organization_codes_ option').removeAttr('selected');
     $('#zoho_crm_organization_codes_').removeAttr('disabled');


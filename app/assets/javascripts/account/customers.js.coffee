load_account_book_type_function= () ->
  $('.add_book_type').unbind 'click'
  $('.add_book_type').on 'click', (e) ->
    $('#for_step_two .modal-header h3').text('Ajouter un journal')
    $('#for_step_two .modal-body').html('')
    organization_id = $('#organization_id').val()

    $.ajax
      url: "/account/organizations/#{organization_id}/customers/2164/book_type_creator/",      
      type: 'GET',
      success: (data) ->
        $('#for_step_two .modal-body').html(data)
        $('#for_step_two').modal('show')
        load_modal_function('')

  $('.edit_book_type').unbind 'click'
  $('.edit_book_type').on 'click', (e) ->
    e.stopPropagation()
    id = $(this).attr('id')
    organization_id = $('#organization_id').val()
    customer_id = $('#customer_id').val()
    $('#for_step_two .modal-header h3').text('Modifier un journal')
    $('#for_step_two .modal-body').html('')

    $.ajax
      url: "/account/organizations/#{organization_id}/customers/#{customer_id}/book_type_creator/#{id}",      
      type: 'GET',
      success: (data) ->
        $('#for_step_two .modal-body').html(data)
        $('#for_step_two').modal('show')
        load_modal_function(id)

load_modal_function= (id) ->
  $('#valider').unbind 'change'
  $('#account_book_type_entry_type').on 'change', (e) ->
    if ( $(this).val() == '2' || $(this).val() == '3')
      if ($(this).hasClass('not_persisted'))
        $('#pre-assignment-attributes').show('')
      else if ($(this).hasClass('persisted'))
        $('#pre-saisie').show('')
    else
      if ($(this).hasClass('persisted'))
        $('#pre-saisie').hide('')
      else if ($(this).hasClass('not_persisted'))
        $('#pre-assignment-attributes').hide('')

  $('#valider').unbind 'click'
  $('#valider').on 'click', (e) ->
    e.stopPropagation()    
    data            = $(".modal form#account_book_type").serialize()
    organization_id = $('#organization_id').val()
    customer_id     = $('#customer_id').val()
    self = $(this)
    self.attr('disabled', true)
    $('.modal#for_step_two #informations').html('<img src="/assets/application/bar_loading.gif" alt="chargement...">')

    url = "/account/organizations/#{organization_id}/journals"
    if (id != '')
      url = "/account/organizations/#{organization_id}/journals/#{id}"

    $.ajax
      url: url,
      data: data,
      type: 'POST',
      success: (data) -> 
        if data.response.indexOf('avec succ') > 0
          $('.modal#for_step_two #informations').html('<div class="alert alert-success margin0" role="alert">'+data.response+'</div>')
          $.ajax
            url: "/account/organizations/#{organization_id}/customers/#{customer_id}/refresh_book_type",            
            success: (data) ->
              $('#book_type').html(data)
              load_account_book_type_function()

          setTimeout(()->
            $('.modal#for_step_two #informations').html('');
            self.attr('disabled', false);
            $('.modal#for_step_two').modal('hide');
          , 4000)
        else
          $('.modal#for_step_two #informations').html('<div class="alert alert-warning margin0" role="alert">'+data.response+'</div>')
          self.attr('disabled', false)

load_vat_function= (id, controlleur) ->
  add   = '#add_'+ id
  table = "#table_"+ id
  table_div = table + " td div"

  $(table_div).unbind 'click'
  $(table_div).on 'click', (e) ->
    e.stopPropagation()
    clas = $(this).attr('class')   
    input_edit  = $(this).parent('td').find('.edit_' + clas).removeClass('hide')
    input_edit.attr('placeholder', $(this).text().trim() )
    content     = $(this).hide()
    input_edit.unbind('focusout')
    input_edit.select()
    input_edit.closest('tr').removeClass('verify')
    input_edit.blur().focus().focusout((e) ->
      e.stopPropagation()
      new_value = $(this).val()      
      if (new_value == $(this).attr('placeholder') || new_value == "")
        content.show()
        input_edit.addClass('hide')        
      else 
        content.html(new_value).show()
        input_edit.addClass('hide')
        input_edit.parent('td').addClass('verify')        
        verify_before_validate(input_edit, controlleur)
      ).on 'keypress',(e) ->
        if(e.which == 13)                
          new_value = $(this).val()
          if (new_value == $(this).attr('placeholder') || new_value == "")
            content.show()
            input_edit.addClass('hide')
          else 
            content.html(new_value).show()
            input_edit.addClass('hide')
            input_edit.parent('td').addClass('verify')
            verify_before_validate(input_edit, controlleur)

  $(add).unbind 'click'
  $(add).on 'click', (e) ->
    line = '<tr><td><div class="vat_code">Cliquez ici pour modifier</div><input class="edit_vat_code hide" type="text" value="" placeholder=""></td><td><div class="vat_code">Cliquez ici pour modifier</div><input class="edit_vat_code hide" type="text" value="" placeholder=""></td><td><div class="vat_code">Cliquez ici pour modifier</div><input class="edit_vat_code hide" type="text" value="" placeholder=""></td></tr>'
    $(table).append(line)
    load_vat_function(id, controlleur)

verify_before_validate= (link) ->
  tr     = link.closest('tr')
  verify = tr.find('.verify')
  if (tr.find('.verify').length == 3 && !tr.hasClass('verify'))
    tr.addClass('verify')
    alert("ok")
    # $.ajax
    #   url: '',
    #   data: '',
    #   dataType: 'json',
    #   type: 'POST',
    #   success: (data) ->
    #     

jQuery ->
  load_account_book_type_function()
  load_vat_function('vat_account', 'vats_accounts')
  load_vat_function('vatc_account', 'accounting_plans')
  load_vat_function('vatp_account', 'accounting_plans')

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

  if $('#customer.edit.mcf').length > 0
    $('#user_mcf_storage').after('<div class="feedback"><img src="/assets/application/bar_loading.gif" alt="chargement..." ></div>')
    $.ajax
      url: $('#user_mcf_storage').data('users-list-url'),
      data: '',
      dataType: 'json',
      type: 'GET',
      success: (data) ->
        original_value = $('#user_mcf_storage').data('original-value') || ''
        for d in data
          option_html = ''
          if original_value.length > 0 && original_value == d['id']
            option_html = '<option value="'+d['id']+'" selected="selected">'+d['name']+'</option>'
          else
            option_html = '<option value="'+d['id']+'">'+d['name']+'</option>'
          $('#user_mcf_storage').append(option_html)
        $('#user_mcf_storage').show()
        $('#user_mcf_storage').chosen
          search_contains: true,
          no_results_text: 'Aucun résultat correspondant à'
        $('.feedback').remove()
        $('input[type=submit]').removeAttr('disabled')
      error: (data) ->
        $('.feedback').remove()
        $('#user_mcf_storage').after('<span class="badge badge-danger fs-origin error">Erreur</span>')

  if $('#customer.errors.mcf').length > 0
    $('#master_checkbox').change ->
      if $(this).is(':checked')
        $('.checkbox').prop('checked', true)
      else
        $('.checkbox').prop('checked', false)

  if $('#customer.edit_softwares_selection').length > 0
    $('#customer.edit_softwares_selection .softwares_setting').on 'click', ->
      if($(this).attr('id') == 'user_softwares_attributes_is_ibiza_used' && $(this).is(':checked'))
        $('#user_softwares_attributes_is_exact_online_used').removeAttr('checked')
      else if($(this).attr('id') == 'user_softwares_attributes_is_exact_online_used' && $(this).is(':checked'))
        $('#user_softwares_attributes_is_ibiza_used').removeAttr('checked')
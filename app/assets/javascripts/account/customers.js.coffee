clean_dialog_box= () ->
  $('#for_step_two .modal-body').html('')
  $('.modal#for_step_two #informations').html('')

load_account_book_type_function= () ->
  $('.add_book_type').unbind 'click'
  $('.add_book_type').on 'click', (e) ->
    clean_dialog_box()
    $('#for_step_two .modal-header h3').text('Ajouter un journal')
    organization_id = $('#organization_id').val()
    customer_id = $('#customer_id').val()

    $.ajax
      url: "/account/organizations/#{organization_id}/customers/#{customer_id}/book_type_creator/",
      type: 'GET',
      success: (data) ->
        $('#for_step_two .modal-body').html(data)
        $('#for_step_two').modal('show')
        load_modal_function('')

  $('.edit_book_type').unbind 'click'
  $('.edit_book_type').on 'click', (e) ->
    e.stopPropagation()
    clean_dialog_box()
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
  $('#account_book_type_entry_type').unbind 'change'
  $('#account_book_type_entry_type').on 'change', (e) ->
    if ( $(this).val() == '2' || $(this).val() == '3')
      $('#pre-assignment-attributes').show('')
    else
      $('#pre-assignment-attributes').hide('')

  $("#toogle_external_journal_list").on 'click', (e)->
    e.preventDefault()
    is_selection_visible = $(".block_selection_journals").is(":visible")
    if is_selection_visible
      $(".block_selection_journals").slideUp('fast')
    else
      $(".block_selection_journals").slideDown('fast')

  $("#select_external_journal").on 'change', (e)->
    selected = $(this).val()
    $("#account_book_type_pseudonym").val(selected)

  $('#valider').unbind 'click'
  $('#valider').on 'click', (e) ->
    e.stopPropagation()

    if window.on_submit_form
      window.on_submit_form('form#account_book_type .account_book_type_vat_accounts')

    data            = $(".modal form#account_book_type").serialize()
    organization_id = $('#organization_id').val()
    customer_id     = $('#customer_id').val()
    self = $(this)
    $('.modal#for_step_two #informations').html('')
    $('.modal#for_step_two #informations').html($('.alert_content_image').clone().removeClass('hide'))

    self.attr('disabled', true)
    url = "/account/organizations/#{organization_id}/journals"
    if (id != '')
      url = "/account/organizations/#{organization_id}/journals/#{id}"

    $.ajax
      url: url,
      data: data,
      type: 'POST',
      success: (data) ->
        $('div.label-section label').each((e) ->
            reinit_label = $(this).text().split(':')[0]
            $(this).text(reinit_label)
            $(this).removeClass('blur')
          )
        $('input').removeClass('input-blur')
        $.each data.response, (champ, messages) ->
          if messages.indexOf('avec suc') > 0
            $('.modal#for_step_two #informations').html($('.alert_success_content').clone().html(messages).removeClass('hide'))
            $.ajax
              url: "/account/organizations/#{organization_id}/customers/#{customer_id}/refresh_book_type",
              success: (data) ->
                $('#book_type').html(data)
                load_account_book_type_function()

            setTimeout( ()->
              $('.modal#for_step_two #informations').html('');
              self.attr('disabled', false);
              $('.modal#for_step_two').modal('hide');
            , 4000)
          else
            label     = $(".account_book_type_" + champ).find('div.label-section label')
            if label.length > 0
              new_label = label.text().toString() + " : "+ messages.join(', ')
              label.text(new_label)
              label.addClass('blur')
              $("#account_book_type_" + champ).addClass('input-blur')
              $('.modal#for_step_two #informations').html('')
            if champ == 'vat_accounts'
              $('input[type="text"]#account_book_type_default_vat_accounts').css("border", "1px solid #b94a48")
              $('input[type="text"]#account_book_type_default_vat_accounts').val("")
              show_error = '<label class="string optional control-label blur">' + messages.join(", ") + '</label>'

              $('input[type="text"]#account_book_type_default_vat_accounts').after(show_error)
            else
              $('.modal#for_step_two #informations').html($('.alert_danger_content').clone().html('Le journal '+ messages).removeClass('hide'))

        self.attr('disabled', false)

load_vat_function= (id, controlleur) ->
  if(controlleur == 'vats_accounts')
    parent_box = '#vat_account'
  else
    parent_box = '#accounting_plan'

  add   = '#add_'+ id
  table = "#table_"+ id
  table_div = table + " td div"

  $(table_div).unbind 'click'
  $(table_div).on 'click', (e) ->
    e.stopPropagation()
    clas = $(this).attr('class')   
    input_edit  = $(this).parent('td').find('.input_edition').removeClass('hide')
    input_edit.attr('placeholder', $(this).text().trim() )
    content = $(this).hide()
    input_edit.unbind('focusout')
    input_edit.select()

    input_edit.blur().focus().focusout((e) ->
      e.stopPropagation()
      new_value = $(this).val()      
      if (new_value == $(this).attr('placeholder'))
        content.show()
        input_edit.addClass('hide')
      else
        input_edit.closest('tr').addClass('verify')
        content.html(new_value || 'Cliquez ici pour modifier').show()
        input_edit.addClass('hide')       
        verify_before_validate(input_edit, controlleur)
      ).on 'keypress',(e) ->
        input_edit.closest('tr').addClass('verify')

        if(e.which == 13)
          new_value = $(this).val()
          if (new_value == $(this).attr('placeholder') || new_value == "")
            content.show()
            input_edit.addClass('hide')
          else 
            content.html(new_value).show()
            input_edit.addClass('hide')
            verify_before_validate(input_edit, controlleur)

  $(add).unbind 'click'
  $(add).on 'click', (e) ->

    if !$(table).hasClass('blocked')
      $(table).addClass('blocked')

      next_tbody = $(parent_box + ' table.hidden_insertion_table tbody')
      if(id == 'vatc_account')
        next_tbody.find('tr:first').removeClass('provider')
        next_tbody.find('tr:first').addClass('customer')
      else if(id == 'vatp_account')
        next_tbody.find('tr:first').removeClass('customer')
        next_tbody.find('tr:first').addClass('provider')

      line = next_tbody.html()

      $(table).find('tbody:last').append(line)
      load_vat_function(id, controlleur)

verify_before_validate= (link, controlleur) ->
  tr    = link.closest('tr')
  table = tr.closest('table')

  if(tr.hasClass('verify'))
    value_counter = 0
    tr.removeClass('verify')
    inputs = tr.find('td .input_edition')

    inputs.each (e)->
      if($(this).val() != null && $(this).val() != 'undefined' && $(this).val() != '')
        value_counter = value_counter + 1

    if(value_counter == inputs.length || value_counter == 0)
      organization_id = $('#organization_id').val()
      customer_id     = $('#customer_id').val()
      entry_id_input  = tr.find('input.entry_id:first')
      entry_type      = null
      data            = null

      if(tr.hasClass('customer'))
        entry_type = 'customer'
      else if(tr.hasClass('provider'))
        entry_type = 'provider'

      if(controlleur == 'vats_accounts')
        url = "/account/organizations/#{organization_id}/customers/#{customer_id}/accounting_plan/vat_accounts/update_multiple.json"
      else
        url = "/account/organizations/#{organization_id}/customers/#{customer_id}/accounting_plan.json"

      if(value_counter == 0)
        tr.remove()
        $(table).removeClass('blocked')
        if(entry_id_input.val() > 0)
          data = { id: entry_id_input.val(), destroy: 'destroy', type: entry_type }
      else
        if(controlleur == 'vats_accounts')
          data = { accounting_plan: { vat_accounts_attributes: { id: entry_id_input.val(), code: tr.find('.input_edition.code:first').val(), nature: tr.find('.input_edition.nature:first').val(), account_number: tr.find('.input_edition.number:first').val() } } }
        else
          attributes = { id: entry_id_input.val(), third_party_account: tr.find('.input_edition.tp_account:first').val(), third_party_name: tr.find('.input_edition.tp_name:first').val(), conterpart_account: tr.find('.input_edition.conterpart:first').val(), code: tr.find('.input_edition.vat_code').val() }

          if(entry_type == 'provider')
            data = { type: entry_type, accounting_plan: { providers_attributes: attributes } }
          else
            data = { type: entry_type, accounting_plan: { customers_attributes: attributes } }

      if(data)
        $.ajax
          url: url,
          data: data,
          dataType: 'json',
          type: 'PATCH',
          success: (result) ->
            $(table).removeClass('blocked')

            if(result)
              entry_id_input.val(result['account']['id'])

load_accounting_plan_function= (id) ->
  button = '#import_'+ id + '_account'

  organization_id = $('#organization_id').val()
  customer_id     = $('#customer_id').val()

  $(button).unbind 'click'
  $(button).on 'click', (e) ->
    e.preventDefault()
    data = new FormData()
    files = $('#'+id+'_file')[0].files[0]

    text_alert = "Merci de séléctionner un fichier avant d'importer"
    url = "/account/organizations/#{organization_id}/customers/#{customer_id}/accounting_plan/import"

    if (id == 'fec')
      text_alert = "Merci de séléctionner un fichier avant de charger un FEC"
      url = "/account/organizations/#{organization_id}/customers/#{customer_id}/accounting_plan/import_fec"

    if (files == undefined)
      $('#information_import').html('')
      $('#information_import').html($(".alert_danger_content").clone().html(text_alert).removeClass('hide')).show('')
      setTimeout(()->
        $('#information_import').hide('');
      , 4000)
      return false

    $('#information_import').html('')

    data.append(id + '_file',files)
    data.append('new_create_book_type','1')
    $('.import_accounting').attr('disabled', true)
    $('#informations').html('')
    $('#information_import').html($('.alert_content_image').clone().removeClass('hide')).show('')

    $.ajax
      url: url,
      data: data,
      type: 'PATCH',
      contentType: false,
      processData: false,
      success: (data) ->
        if (id != 'fec')
          $('#partial_table').html(data)
          $('#information_import').html('')
          $('.import_accounting').attr('disabled', false)
          load_vat_function('vatc_account', 'accounting_plans')
          load_vat_function('vatp_account', 'accounting_plans')
        else
          if (data != undefined)
            $('#for_step_two .modal-header h3').text('Paramétrage import FEC')
            $('#for_step_two .close').hide()
            $('#for_step_two .modal-footer').hide()
            $('#for_step_two').find('.modal-body:first').hide()
            $('#for_step_two .modal-dialog_box').append(data)
            $('#for_step_two').modal('show')

            $('#for_step_two input#import_button').unbind 'click'
            $('#for_step_two input#import_button').on 'click', (e) ->
              e.preventDefault()
              $(this).attr('disabled', true)
              $('#informations').html('')
              $('#informations').html($('.alert_content_image').clone().first().removeClass('hide'))

              $.ajax
                url: "/account/organizations/#{organization_id}/customers/#{customer_id}/accounting_plan/import_fec_processing",
                data: $('form#importFecAfterConfiguration').serialize(),
                contentType: false,
                processData: false,
                success: (data) ->
                  $('#partial_table').html(data)
                  $('#information_import').html('')
                  $('.import_accounting').attr('disabled', false)
                  load_vat_function('vatc_account', 'accounting_plans')
                  load_vat_function('vatp_account', 'accounting_plans')
                  $('#for_step_two .modal-dialog_box').html('')
                  $('#for_step_two .close').show()
                  $('#for_step_two .modal-footer').show()
                  $('#for_step_two').find('.modal-body:first').show()
                  $('#for_step_two').modal('hide')
          else
            $('#information_import').html($('.alert_warning_content').clone().html('Type de fichier non reconnu').removeClass('hide'))
            setTimeout(()->
                $('#information_import').hide('');
              , 3000)
            $('.import_accounting').attr('disabled', false)

get_ibiza_customers_list = (element)->
  element.after('<div class="removable-feedback feedback"></div>')
  $.ajax
    url: element.data('users-list-url'),
    data: '',
    dataType: 'json',
    type: 'GET',
    success: (data) ->
      original_value = element.data('original-value') || ''
      for d in data
        option_html = ''
        if original_value.length > 0 && original_value == d['id']
          option_html = '<option value="'+d['id']+'" selected="selected">'+d['name']+'</option>'
        else
          option_html = '<option value="'+d['id']+'">'+d['name']+'</option>'
        element.append(option_html)
      element.show()
      element.chosen
        search_contains: true,
        no_results_text: 'Aucun résultat correspondant à'
      $('.removable-feedback').remove()
      if $('input[type=submit]').length > 0
        $('input[type=submit]').removeAttr('disabled')
      $('#create_customer .softwares-section').css('display', 'none')

check_input_number = ->
  $('#personalize_subscription_package_form .subscription_number_of_journals .special_input').focus()

  $('#personalize_subscription_package_form .subscription_number_of_journals .special_input').click (e) -> update_price()

  $('#personalize_subscription_package_form .subscription_number_of_journals .special_input').keypress (e) ->
    e.preventDefault()

update_form = ->
  lock_package()
  options = ['number_of_journals', 'pre_assignment']
  selected_options = []

  if $('#personalize_subscription_package_form input#subscription_subscription_option_is_basic_package_active').is(':checked')
    active_option_of('basic')
    selected_options.push 'number_of_journals', 'pre_assignment'
  if $('#personalize_subscription_package_form input#subscription_subscription_option_is_idox_package_active').is(':checked')
    active_option_of('idox')
    selected_options.push 'number_of_journals'
  if $('#personalize_subscription_package_form input#subscription_subscription_option_is_micro_package_active').is(':checked')
    active_option_of('micro')
    selected_options.push 'number_of_journals'
  if $('#personalize_subscription_package_form input#subscription_subscription_option_is_mini_package_active').is(':checked')
    active_option_of('mini')
    selected_options.push 'number_of_journals', 'pre_assignment'
  if $('#personalize_subscription_package_form input#subscription_subscription_option_is_retriever_package_active').is(':checked')
    remove_active_class()
    selected_options.push 'number_of_journals'
  if $('#personalize_subscription_package_form input#subscription_is_pre_assignment_active_true').is(':checked')
    selected_options.push 'number_of_journals'
  if $('#personalize_subscription_package_form input#subscription_is_pre_assignment_active_false').is(':checked')
    selected_options.push 'number_of_journals'

  for option in options
    if selected_options.indexOf(option) != -1
      $('.'+option).show()
      if (option == 'pre_assignment')
        if $('#personalize_subscription_package_form input#is_pre_assignment_active_hidden').val() > 0
          $('#personalize_subscription_package_form input#subscription_is_pre_assignment_active_true').prop('checked', true)
    else
      $('.'+option).hide()

  uncheck_all_options()
  update_price()

uncheck_all_options = ->
  $('#personalize_subscription_package_form .option_checkbox').each (e) ->
    if !$(this).hasClass('checkbox_active')
      $(this).removeAttr('checked')

active_option_of = (group) ->
  $("#personalize_subscription_package_form .#{group}_option").removeAttr('disabled')
  remove_active_class()

  $("#personalize_subscription_package_form #subscription_subscription_option_is_#{group}_package_active").addClass('active')
  $("#personalize_subscription_package_form .form_check_#{group}_package").addClass('active_options')
  $("#personalize_subscription_package_form .active_options input[type='checkbox']").addClass('checkbox_active')

remove_active_class = ->
  $("#personalize_subscription_package_form .active").removeClass('active')
  $("#personalize_subscription_package_form .active_options").removeClass('active_options')
  $("#personalize_subscription_package_form .checkbox_active").removeClass('checkbox_active')

get_data_original_value_of = (group, option) ->
  return parseInt($("#personalize_subscription_package_form .#{group} input#{option}").data('original-value'))

lock_package = ->
  $("#personalize_subscription_package_form .option_checkbox").attr('disabled', 'disabled')

check_commitment = ->
  if $('#personalize_subscription_package_form .commitment_pending').length > 0
    $('#personalize_subscription_package_form .radio-button').attr('disabled', 'disabled')
    $('#personalize_subscription_package_form .commitment_pending').each (e) ->
      if $(this).is(':checked')
        $(this).removeAttr('disabled')

show_ibiza_customer = ->
  $('#create_customer input.ibiza-customer-select').change ->
    if @checked
      $('#create_customer .softwares-section').css('display', 'block')
    else
      $('#create_customer .softwares-section').css('display', 'none')

  if $('#create_customer .softwares-section .ibiza-customers-list').length > 0
    get_ibiza_customers_list($('#create_customer .softwares-section .ibiza-customers-list'))

update_price = ->
  price_list = {
    #standard prices
    'subscription':        10,
    'idox':                5,
    'pre_assignment':      9,
    'return_paper':        10,
    'retriever':           5,
    'reduced_retriever':   3,
     #special prices
    'subscription_plus':   1,
  }

  selected_options = []
  price = 0
  options = []

  if $('#personalize_subscription_package_form input#subscription_subscription_option_is_idox_package_active').is(':checked') || get_data_original_value_of('form-check', '#subscription_subscription_option_is_idox_package_active') == 1
    options.push 'idox'
  if $('#personalize_subscription_package_form input#subscription_subscription_option_is_basic_package_active').is(':checked') || get_data_original_value_of('form-check', '#subscription_subscription_option_is_basic_package_active') == 1
    options.push 'subscription', 'subscription_plus', 'pre_assignment'
  if $('#personalize_subscription_package_form .active_options input#subscription_is_mail_package_active').is(':checked') || get_data_original_value_of('active_options', '#subscription_is_mail_package_active') == 1
    options.push 'return_paper'
  if $('#personalize_subscription_package_form .active_options input#subscription_is_retriever_package_active').is(':checked') || get_data_original_value_of('active_options', '#subscription_is_retriever_package_active') == 1
    options.push $('#personalize_subscription_package_form input#subscription_is_retriever_package_active').data('retriever-price-option')
  if $('#personalize_subscription_package_form input#subscription_subscription_option_is_retriever_package_active').is(':checked') || get_data_original_value_of('form-check', '#subscription_subscription_option_is_retriever_package_active') == 1
    options.push $('#personalize_subscription_package_form input#subscription_subscription_option_is_retriever_package_active').data('retriever-price-option')
  if $('#personalize_subscription_package_form input#subscription_subscription_option_is_micro_package_active').is(':checked') || get_data_original_value_of('form-check', '#subscription_subscription_option_is_micro_package_active') == 1
    options.push 'subscription'
  if $('#personalize_subscription_package_form input#subscription_subscription_option_is_mini_package_active').is(':checked') || get_data_original_value_of('form-check', '#subscription_subscription_option_is_mini_package_active') == 1
    options.push 'subscription', 'subscription_plus', 'pre_assignment'
  options = _.uniq(options)

  for option in options
    if option == 'pre_assignment'
      if $('#subscription_is_pre_assignment_active_true').is(':checked')
        selected_options.push 'pre_assignment'
    else
      selected_options.push option

  if options.length > 0
    number_of_journals = parseInt($('input[name="subscription[number_of_journals]"]').val())
    if number_of_journals > 5
      price += number_of_journals - 5

  for option in selected_options
    price += price_list[option]

  $('.total_price').html(price+",00€ HT")

jQuery ->  
  if ($('.import_dialog').length > 0)
    $('#import_dialog').modal('show')

  if $('#customer.edit_period_options').length > 0
    $('#user_authd_prev_period').on 'change', ->
      $('#user_auth_prev_period_until_day').val(0)

    $('#user_auth_prev_period_until_day').on 'change', ->
      $('#user_authd_prev_period').val(1)

  if $('#customer.edit.ibiza').length > 0
    get_ibiza_customers_list($('#user_ibiza_id'))

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

  load_account_book_type_function()
  load_vat_function('vat_account', 'vats_accounts')
  load_vat_function('vatc_account', 'accounting_plans')
  load_vat_function('vatp_account', 'accounting_plans')
  load_accounting_plan_function('fec')
  load_accounting_plan_function('providers')
  load_accounting_plan_function('customers')

  $('#personalize_subscription_package_form .form-check.form-check-inline, #personalize_subscription_package_form span.radio.pre-assignment-state').tooltip()
  
  $('#personalize_subscription_package_form input[type="checkbox"].option_checkbox').click (e) -> update_price()

  $('#personalize_subscription_package_form .subscription_number_of_journals input[type="number"].special_input').bind 'keyup keydown change', (e) ->
    e.preventDefault()
    update_price()

  $('#personalize_subscription_package_form input[type="radio"].radio-button').on 'click', (e) ->
    $("#personalize_subscription_package_form .form-check input").data('original-value', 0)

    if !$("##{e.currentTarget.id}").hasClass('active')
      class_list = $(this).attr('class').split(/\s+/)
      lock_package()

      $.each class_list, (index, item) ->
        if item == 'idox-check-radio'
          $('#personalize_subscription_package_form input#subscription_subscription_option_is_idox_package_active').attr('checked', 'checked')
          active_option_of('idox')
        if item == 'micro-check-radio'
          $('#personalize_subscription_package_form input#subscription_subscription_option_is_micro_package_active').attr('checked', 'checked')
          active_option_of('micro')
        if item == 'mini-check-radio'
          $('#personalize_subscription_package_form input#subscription_subscription_option_is_mini_package_active').attr('checked', 'checked')
          active_option_of('mini')
        if item == 'basic-check-radio'
          $('#personalize_subscription_package_form input#subscription_subscription_option_is_basic_package_active').attr('checked', 'checked')
          active_option_of('basic')
        if item == 'retriever-uniquess-check-radio'
          $('#personalize_subscription_package_form input#subscription_subscription_option_is_retriever_package_active').attr('checked', 'checked')
          remove_active_class()
        if item == 'is_pre_assignment_active_true'
          $('#personalize_subscription_package_form input#subscription_is_pre_assignment_active_true').attr('checked', 'checked')
          $('#personalize_subscription_package_form input#subscription_is_pre_assignment_active_false').removeAttr('checked')
          $('#personalize_subscription_package_form input#is_pre_assignment_active_hidden').val(1)
        if item == 'is_pre_assignment_active_false'
          $('#personalize_subscription_package_form input#subscription_is_pre_assignment_active_false').attr('checked', 'checked')
          $('#personalize_subscription_package_form input#subscription_is_pre_assignment_active_true').removeAttr('checked')
          $('#personalize_subscription_package_form input#is_pre_assignment_active_hidden').val(0)

      update_form()
      uncheck_all_options()
      update_price()

  if $(".edit.my_unisoft").length > 0
    $("input[name='user[my_unisofts][customer_auto_deliver]']").each (index, element) =>
      if $(element).val() == $("#auto_deliver_customer").val()
        $(element).attr('checked', 'checked')
        $(element).parent().addClass('checked')

    $('#remove_customer').on 'click', (e) ->
      e.stopPropagation()
      if $(this).is(":checked")
        $("input#user_my_unisofts_api_token").removeAttr('required')
        $("input#required").removeClass('required')
      else
        $("input#user_my_unisofts_api_token").attr('required', 'required')
        $("input#required").addClass('required')

  check_input_number()
  show_ibiza_customer()
  check_commitment()
  update_form()
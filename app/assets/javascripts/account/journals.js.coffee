update_form = ->
  if parseInt($("#account_book_type_entry_type").val()) > 1 && parseInt($("#account_book_type_entry_type").val()) < 4
    toggle_required_field('enable')
    $('.pre-assignment-attributes').fadeIn('slow')
  else
    toggle_required_field('disable')
    $('.pre-assignment-attributes').fadeOut('fast')

create_prev_button = (i) ->
  step_name = 'step' + i
  $('#' + step_name + 'commands').append("<a href='#' id='" + step_name + "Prev' class='prev btn btn-secondary'>< Précédent</a>")

  $('#' + step_name + 'Prev').bind 'click', (e) ->
    $('#' + step_name).hide()
    $('#step' + (i - 1)).fadeIn('slow')
    $('.form-actions input[type="submit"]').attr('disabled', 'disabled');

create_next_button = (i, count) ->
  step_name = 'step' + i;
  $('#' + step_name + 'commands').append("<a href='#' id='" + step_name + "Next' class='next btn btn-secondary'>Suivant ></a>")

  $('#' + step_name + "Next").bind 'click', (e) ->
    $('#' + step_name).hide()
    $('#step' + (i + 1)).fadeIn('slow')
    if (i + 2 == count)
      $('.form-actions input[type="submit"]').removeAttr('disabled');

form_to_wizard = ->
  steps = $('form').find('.step')
  count = steps.size()
  if (count == 1)
    $('.form-actions input[type="submit"]').removeAttr('disabled');
  else
    $('.form-actions input[type="submit"]').attr('disabled', 'disabled');
    steps.each (i) ->
      $(this).wrap("<div id='step" + i + "'></div>")
      $(this).append("<div id='step" + i + "commands' class='commands'></div>")

      if (i == 0)
        create_next_button(i, count)
      else if (i == count - 1)
        $('#step' + i).hide()
        create_prev_button(i)
      else
        $('#step' + i).hide()
        create_prev_button(i)
        create_next_button(i, count)

      $(this).fadeIn('slow')

toggle_required_field = (type) ->
  if (type == 'enable')
    $('#new_account_book_type .can_be_required').attr('required', 'required')
  else
    $('#new_account_book_type .can_be_required').removeAttr('required')

vat_account_info = (option)->
  hint_label = ''
  if option == 'hint_label'
    hint_label = 'Compte de TVA par défaut appliqué à tous les documents dans le journal comptable iDocus'
  if $('input[type=hidden]#required_new_vat_accounts_element').length > 0
    hint_label = $('input[type=hidden]#required_new_vat_accounts_element').attr(option)
  return hint_label

vat_accounts_can_be_required = ->
  if $('input[type=hidden]#required_new_vat_accounts_element').length > 0
    return $('input[type=hidden]#required_new_vat_accounts_element').val()

vat_account_field = ->
  if $('#journal form, #for_step_two.modal').length > 0
    $('a.add_vat_account_field').unbind('click')
    $('a.add_vat_account_field').on 'click', (e) ->
      e.preventDefault()
      add_vat_account_field('10', 445660)

      remove_vat_account_field()

add_vat_account_field = (rate, vat_account) ->
  input_field = '<div class="form-group clearfix string optional account_book_type_vat_accounts">'
  input_field += '<div class="label-section">'
  input_field += '<input class="form-control string optional vat_accounts_label account_book_type_label_vat_accounts" type="number" name="account_book_type[vat_accounts_label]" value="' + rate + '" min="1" max="20" step="0.1" id="account_book_type_label_vat_accounts" data-toggle="tooltip" data-placement="top" title="Taux de TVA (1-20)%" style="height: 31px;">'
  input_field += '<i class="help-block" id="errmsg" style="color: red;"></i>'
  input_field += '</div>'
  input_field += '<div class="control-section">'
  input_field += '<div class="row">'
  input_field += '<div class="col-10" style="margin-right: -36px;">'
  input_field += '<input class="form-control string optional vat_accounts" type="text" name="account_book_type[vat_accounts_rate]" value="' + vat_account + '" id="account_book_type_vat_accounts">'
  input_field += '</div>'
  input_field += '<div class="col-1 float-right margin1left" style="margin-right: 10px;">'
  input_field += '<a id="remove_vat_accounts_field" href="#" class="btn btn-default" data-toggle="tooltip" data-placement="right" title="Supprimer">X</a>'
  input_field += '</div>'
  input_field += '</div>'
  input_field += '</div>'
  input_field += '</div>'

  $('.pre-assignment-attributes #account_book_type_with_default_vat_accounts, #pre-assignment-attributes #account_book_type_with_default_vat_accounts').after(input_field)

  $('#account_book_type_label_vat_accounts').focus()

  $('#remove_vat_accounts_field[data-toggle="tooltip"], #account_book_type_label_vat_accounts[data-toggle="tooltip"]').tooltip()

  $('#account_book_type_label_vat_accounts').bind 'blur keypress input', (e) ->
    if e.which != 8 && e.which != 0 && (e.which < 48 or e.which > 57) && !(e.keyCode == 46 || e.charCode == 46 || e.keyCode == 44 || e.charCode == 44) && !(e.which == 13 || e.keyCode == 13 || e.key == "Enter")
      $('#errmsg').html('Chiffre uniquement ou avec un point ou une virgule').show().delay(5000).fadeOut 'slow'
      return false
    value = $(this).val()
    regex = /^\d{1,2}([,.]{1}\d{1,2})?$/
    if (e.type == 'blur' && !regex.test(value)) || (!regex.test(value) && (e.which == 13 || e.keyCode == 13 || e.key == "Enter"))
      $('#errmsg').html('Saisie incorrecte').show().delay(5000).fadeOut 'slow'
      return false

    if e.type == 'input'
      value = $(this).val()
      if parseFloat(value) < 1 || parseFloat(value) > 20
        $('#errmsg').html('Taux de TVA doit être inclus entre (1-20%)').show().delay(5000).fadeOut 'slow'
        return false

add_default_vat_account = (vat_account) ->
  input_field = '<div class="form-group clearfix string optional account_book_type_vat_accounts" id="account_book_type_with_default_vat_accounts">'
  input_field += '<div class="label-section">'
  input_field += '<input class="form-control string optional vat_accounts_label" type="text" name="account_book_type[vat_accounts_label]" value="Compte de TVA par défaut" id="account_book_type_default_label_vat_accounts" style="height: 31px;" disabled>'
  input_field += '<i class="help-block">' + vat_account_info("hint_label") + '</i>'
  input_field += '</div>'
  input_field += '<div class="control-section">'
  input_field += '<div class="row">'
  input_field += '<div class="col-10" style="margin-right: -36px;">'
  input_field += '<input class="form-control string optional vat_accounts" type="text" name="account_book_type[vat_accounts_rate]" value="' + vat_account + '" id="account_book_type_default_vat_accounts">'
  input_field += '<i class="help-block">' + vat_account_info("hint_input") + '</i>'
  input_field += '</div>'
  input_field += '</div>'
  input_field += '</div>'
  input_field += '</div>'

  $('.pre-assignment-attributes .vat_account_field, #pre-assignment-attributes .vat_account_field').after(input_field)

show_vat_account_field = ->
  add_default_vat_account(445660)

  vat_accounts = $('input[type=hidden]#account-book-type-vat-accounts-hidden').val()
  if !(vat_accounts == '' || vat_accounts == null || vat_accounts == 'undefined' || vat_accounts == undefined)
    try
      vat_accounts = JSON.parse(vat_accounts)
      for rate, vat_account of vat_accounts
        if /Compte de TVA par défaut/.test(rate) || rate == '0'
          $('input[type="text"]#account_book_type_default_vat_accounts').val(vat_account)
          $('input[type="text"]#account_book_type_default_vat_accounts').change()

          if $('.account_book_type_vat_accounts.error').length > 0
            $('input[type="text"]#account_book_type_default_vat_accounts').css("border", "1px solid #b94a48")
            $('input[type="text"]#account_book_type_default_vat_accounts').val("")
        if !(rate == '' || rate == 'undefined' || rate == null || rate == undefined || vat_account == '' || vat_account == 'undefined' || vat_account == null || vat_account == undefined || /Compte de TVA par défaut/.test(rate) || rate == '0')
          add_vat_account_field(rate, vat_account)
    catch e
      return false

  remove_vat_account_field()

remove_vat_account_field = ->
  $('.account_book_type_vat_accounts #remove_vat_accounts_field').on 'click', (e) ->
    e.preventDefault()
    $('[data-toggle="tooltip"]').tooltip("hide")
    $(this).closest('.account_book_type_vat_accounts').remove()

window.on_submit_form = (form)->
  vat_accounts = {}
  $(form).each (index,element) ->
    vat_account = $(this)
    label = vat_account.find('input[type="text"].vat_accounts_label, input[type="number"].vat_accounts_label').val()
    field = vat_account.find('input[type="text"].vat_accounts').val()

    if label == 'Compte de TVA par défaut'
      label = '0'

    if !(/undefined/.test(field) || /undefined/.test(label) || label == null || label == undefined || label == '' || field == null || field == '' || field == undefined)
      vat_accounts[label] = field
  vat_accounts = JSON.stringify(vat_accounts)
  $('input[type=hidden]#account-book-type-vat-accounts-hidden').val(vat_accounts)




jQuery ->
  vat_account_field()

  if $('#journal form, #for_step_two.modal').length > 0
    if $('#journal.new form').length > 0
      form_to_wizard()

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

    update_form()
    $("#account_book_type_entry_type, #account_book_type_account_type").change ->
      update_form()

    $('#for_step_two.modal').on 'show.bs.modal', (e) ->
      if $("#new_create_book_type").length > 0
        vat_account_field()
        show_vat_account_field()

    show_vat_account_field()

    $('#journal form').submit ->
      window.on_submit_form('#journal form .account_book_type_vat_accounts')
      true

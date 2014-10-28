update_form = ->
  if parseInt($("#account_book_type_entry_type").val()) > 1
    $('.pre-assignment-attributes').show()
  else
    $('.pre-assignment-attributes').hide()

disable_default_account_fields = ->
  if $("#account_book_type_account_number").val().length > 0 || $("#account_book_type_charge_account").val().length > 0
    $("#account_book_type_default_account_number").attr('disabled', 'disabled')
    $("#account_book_type_default_charge_account").attr('disabled', 'disabled')
  else
    $("#account_book_type_default_account_number").removeAttr('disabled')
    $("#account_book_type_default_charge_account").removeAttr('disabled')

disable_account_fields = ->
  if $("#account_book_type_default_account_number").val().length > 0 || $("#account_book_type_default_charge_account").val().length > 0
    $("#account_book_type_account_number").attr('disabled', 'disabled')
    $("#account_book_type_charge_account").attr('disabled', 'disabled')
  else
    $("#account_book_type_account_number").removeAttr('disabled')
    $("#account_book_type_charge_account").removeAttr('disabled')

jQuery ->
  if $('#journal form').length > 0
    update_form()
    $("#account_book_type_entry_type").change ->
      update_form()

    disable_default_account_fields()
    $("#account_book_type_account_number, #account_book_type_charge_account").change ->
      disable_default_account_fields()

    disable_account_fields()
    $("#account_book_type_default_account_number, #account_book_type_default_charge_account").change ->
      disable_account_fields()

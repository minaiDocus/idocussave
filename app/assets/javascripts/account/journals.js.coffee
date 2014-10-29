update_form = ->
  if parseInt($("#account_book_type_entry_type").val()) > 1
    $('.pre-assignment-attributes').show()
  else
    $('.pre-assignment-attributes').hide()

update_fields = ->
  if ($("#account_book_type_account_number").val().length > 0 || $("#account_book_type_charge_account").val().length > 0) && $("#account_book_type_default_account_number").val().length == 0 && $("#account_book_type_default_charge_account").val().length == 0
    $("#account_book_type_default_account_number").attr('readonly', true)
    $("#account_book_type_default_charge_account").attr('readonly', true)
  else
    $("#account_book_type_default_account_number").removeAttr('readonly')
    $("#account_book_type_default_charge_account").removeAttr('readonly')

  if ($("#account_book_type_default_account_number").val().length > 0 || $("#account_book_type_default_charge_account").val().length > 0) && $("#account_book_type_account_number").val().length == 0 && $("#account_book_type_charge_account").val().length == 0
    $("#account_book_type_account_number").attr('readonly', true)
    $("#account_book_type_charge_account").attr('readonly', true)
  else
    $("#account_book_type_account_number").removeAttr('readonly')
    $("#account_book_type_charge_account").removeAttr('readonly')

jQuery ->
  if $('#journal form').length > 0
    update_form()
    $("#account_book_type_entry_type").change ->
      update_form()

    update_fields()
    $("#account_book_type_account_number, #account_book_type_charge_account, #account_book_type_default_account_number, #account_book_type_default_charge_account").change ->
      update_fields()

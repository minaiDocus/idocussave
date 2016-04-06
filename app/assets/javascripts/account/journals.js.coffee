update_form = ->
  if parseInt($("#account_book_type_entry_type").val()) > 1
    $('.pre-assignment-attributes').show()
  else
    $('.pre-assignment-attributes').hide()

create_prev_button = (i) ->
  step_name = 'step' + i
  $('#' + step_name + 'commands').append("<a href='#' id='" + step_name + "Prev' class='prev'>< Précédent</a>")

  $('#' + step_name + 'Prev').bind 'click', (e) ->
    $('#' + step_name).hide()
    $('#step' + (i - 1)).show()
    $('.form-actions').hide()

create_next_button = (i, count) ->
  step_name = 'step' + i;
  $('#' + step_name + 'commands').append("<a href='#' id='" + step_name + "Next' class='next'>Suivant ></a>")

  $('#' + step_name + "Next").bind 'click', (e) ->
    $('#' + step_name).hide()
    $('#step' + (i + 1)).show()
    if (i + 2 == count)
      $('.form-actions').show()

form_to_wizard = ->
  steps = $('form').find('fieldset')
  count = steps.size()
  if (count == 1)
    $('.form-actions').show()
  else
    $('.form-actions').hide()
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

      $(this).show()

jQuery ->
  if $('#journal form').length > 0
    if $('#journal.new form').length > 0
      form_to_wizard()

    update_form()
    $("#account_book_type_entry_type, #account_book_type_account_type").change ->
      update_form()

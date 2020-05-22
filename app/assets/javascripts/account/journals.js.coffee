update_form = ->
  if parseInt($("#account_book_type_entry_type").val()) > 1
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

jQuery ->
  if $('#journal form').length > 0
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

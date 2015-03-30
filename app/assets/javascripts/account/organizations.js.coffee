#//= require jquery_nested_form

jQuery ->
  if $('#organizations .edit_options').length > 0
    $('.all_organizations').click (e) ->
      e.preventDefault()
      $('.organization').attr('checked', true)
    $('.no_organizations').click (e) ->
      e.preventDefault()
      $('.organization').attr('checked', false)

load_connectors_list= () ->
  $("#body_table_loading").removeClass('hide')
  $.ajax
    url: '/admin/budgea_retriever/export_connector_list' 
    type: 'GET'
    success: (data) ->
      $("#body_table_loading").addClass('hide')
      $('#body_table').html(data)

load_all_users= () ->
  $("#body_table_loading").removeClass('hide')
  $('.onglets').attr('disabled', true)
  $.ajax
    url: '/admin/budgea_retriever/get_all_users' 
    type: 'GET'
    success: (data) ->
      $("#body_table_loading").addClass('hide')
      $('#body_table').html(data)

jQuery ->
  $('#launcher').on 'click', (e) ->
    $(this).attr('disabled', true)
    load_connectors_list()
    $(this).attr('disabled', false)

  $('.onglets').on 'click', (e) ->
    e.preventDefault()
    $('.body_table').addClass('hide').removeClass('active')
    $("."+$(this).attr('id')+"_table").removeClass('hide').addClass('active')

  $('#all_users').on 'click', (e) ->
    load_all_users()
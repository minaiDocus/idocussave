budgea_users = () ->
  data = window.location.search.substring(1,window.location.search.length)
  $('#archive_budgea_users .archive_budgea_users_content tr.row-budgea-users').each (e)->
    budgea_user_id = $(this).attr('id').split('-')[1]

    $.ajax(
      type: 'GET',
      data: { budgea_user_id: budgea_user_id, data }
      url: '/admin/archives/budgea_users',
      contentType: 'application/json',
      ).success (response) ->
        $("#archive_budgea_users .archive_budgea_users_content tr#row-" + budgea_user_id).html(response)


jQuery ->
  #budgea_users()
  $('#archive_budgea_users td.show_tooltip, #archive_budgea_retrievers td.show_tooltip').tooltip()
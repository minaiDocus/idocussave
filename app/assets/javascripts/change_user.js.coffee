jQuery ->
  $('#change_user').on('shown', ->
    $('#user_code').focus().select()
  )

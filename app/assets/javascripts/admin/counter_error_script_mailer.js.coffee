launch_request = (_url, _data) ->
  $.ajax(
    type: 'POST',
    url: 'counter_error_script_mailer/' + _url,
    contentType: 'application/json',
    data: _data).success (response) ->
    console.log response
    window.location.reload()


jQuery ->
  $('.set-state').on 'click', (e) ->
    e.preventDefault()
    id = $(this).attr('id')
    is_enable = $(this).attr('state')

    id = id.split('_')[1]

    _url = 'set_state'

    _data = JSON.stringify(
      id: id
      is_enable: is_enable)

    launch_request(_url, _data)

  $('.set-counter-to-initialize').on 'click', (e) ->
    e.preventDefault()
    id = $(this).attr('id')
    counter = $(this).attr('counter')

    id = id.split('_')[1]

    _url = 'set_counter'

    _data = JSON.stringify(
      id: id
      counter: counter)

    launch_request(_url, _data)
      
      

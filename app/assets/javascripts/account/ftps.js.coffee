update_path_preview = ->
  path = $('#ftp_path').val()
  path = path.replace(':code', 'CODE%001')
  path = path.replace(':year', '2017')
  path = path.replace(':month', '01')
  path = path.replace(':account_book', 'AC')
  path = path.replace(/\//g, ' > ')
  path = path.replace(/>\W$/, '')
  $('#prev_output_path').val(path)

jQuery ->
  $('.do-popover').popover()

  update_path_preview()
  $('#ftp_path').on 'change', ->
    update_path_preview()

get_last_content_for = (name) ->
  $('.content.' + name).html('<div class="loading-data"></div>');
  $.get '/account/account/' + name, (data) ->
    $('.content.' + name).html(data)

jQuery ->
  if navigator.userAgent.toLowerCase().indexOf('msie') != -1
    $('.ie-message').show()

  $('#news.modal.active').modal(show: true)

  tab_name = $('.tab-pane.active').attr('id')
  get_last_content_for(tab_name) if tab_name

  $('a.last_scans').click ->
    get_last_content_for('last_scans')
  $('a.last_uploads').click ->
    get_last_content_for('last_uploads')
  $('a.last_dematbox_scans').click ->
    get_last_content_for('last_dematbox_scans')
  $('a.last_retrieved').click ->
    get_last_content_for('last_retrieved')

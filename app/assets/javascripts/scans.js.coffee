create_return_labels = ->
  $.ajax
    url: "/scans/return_labels/#{window.year()}/#{window.month()}/#{window.day()}",
    data: $('#returnLabelsForm .form').serialize(),
    datatype: 'json',
    type: 'POST',
    success: (data) ->
      $('#returnLabelsForm input[type=submit]').removeClass('disabled')
      $('#returnLabelsDialog iframe').attr('src', '/scans/return_labels')

new_return_labels = ->
  $('#returnLabelsForm').html('')
  $('#returnLabelsDialog iframe').attr('src', '')
  $.ajax
    url: "/scans/return_labels/new/#{window.year()}/#{window.month()}/#{window.day()}",
    data: {},
    datatype: 'json',
    type: 'GET',
    success: (data) ->
      $('#returnLabelsForm').html(data)
      $('#returnLabelsForm input[type=submit]').click (e) ->
        e.preventDefault()
        unless $(this).hasClass('disabled')
          $(this).addClass('disabled')
          create_return_labels()

jQuery ->
  $('#returnLabelsDialog').on 'show', ->
    new_return_labels()

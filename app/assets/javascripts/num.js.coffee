create_return_labels = ->
  $.ajax
    url: '/num/return_labels',
    data: $('#returnLabelsForm .form').serialize(),
    datatype: 'json',
    type: 'POST',
    success: (data) ->
      $('#returnLabelsForm input[type=submit]').removeClass('disabled')
      $('#returnLabelsDialog iframe').attr('src', '/num/return_labels')
  
new_return_labels = ->
  $('#returnLabelsForm').html('')
  $('#returnLabelsDialog iframe').attr('src', '')
  $.ajax
    url: '/num/return_labels/new',
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
jQuery ->
  if $('#file_naming_policy.edit').length > 0
    update_preview = ->
      $.ajax
        url: $('form').attr('action') + '/preview',
        type: 'POST',
        data: $('form').serialize(),
        dataType: 'json',
        success: (data) ->
          $('#result .value').text(data['file_name'])

    update_preview()
    $('form input, form select').on 'change', ->
      update_preview()

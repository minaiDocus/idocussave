Idocus.vent = _.extend({}, Backbone.Events);

Idocus.initialize = ->
  @account_journals_router = new Idocus.Routers.Account.Journals()
  Backbone.history.start()

$(document).ready ->
  Idocus.initialize()

  $('input[type=checkbox].inplace').click ->
    $node = $(this)
    id = $node.attr('id')
    value = $node.is(':checked')
    url = '/account/journals/' + id + '/update_is_default_status'
    hsh = { _method: 'PUT', value: value }
    $.ajax
      url: url,
      data: hsh,
      datatype: 'json',
      type: 'POST',
      beforeSend: ->
        $node.hide()
        $('#spinner_'+id).show()
      success: (data) ->
        $node.show()
        $('#spinner_'+id).hide()
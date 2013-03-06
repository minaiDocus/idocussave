class Idocus.Models.Journal extends Backbone.RelationalModel

  urlRoot: 'journals'

  update_requested_users: ->
    ids = @get('requested_client_ids')
    ids = 'empty' if ids.length == 0
    data = { account_book_type: { requested_client_ids: ids } }
    $.ajax
      url: "#{@urlRoot}/#{@get('id')}/update_requested_users"
      type: 'POST'
      data: data
      datatype: 'json'
class Idocus.Models.Journal extends Backbone.Model

  urlRoot: 'journals'

  update_clients: ->
    ids = @get('client_ids')
    ids = 'empty' if ids.length == 0
    data = { account_book_type: { client_ids: ids } }
    $.ajax
      url: "#{@urlRoot}/#{@get('id')}"
      type: 'PUT'
      data: data
      datatype: 'json'
      complete: ->
        Idocus.vent.trigger('stopLoading')
      error: ->
        $('.alerts').append("<div class='row-fluid'><div class='span12 alert alert-error'><a class='close' data-dismiss='alert'></a>Une erreur est survenue et l'administrateur a été prévenu.</div></div>")

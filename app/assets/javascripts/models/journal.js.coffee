class Idocus.Models.Journal extends Backbone.Model

  urlRoot: 'journals'

  update_requested_users: ->
    ids = @get('requested_client_ids')
    ids = 'empty' if ids.length == 0
    data = { account_book_type: { requested_client_ids: ids } }
    $.ajax
      url: "#{@urlRoot}/#{@get('id')}/update_requested_users"
      type: 'PUT'
      data: data
      datatype: 'json'
      complete: ->
        Idocus.vent.trigger('stopLoading')
      error: ->
        $('.alerts').append("<div class='row-fluid'><div class='span12 alert alert-error'><a class='close' data-dismiss='alert'></a>Une erreur est survenue et l'administrateur a été prévenu.</div></div>")

  unassigningUsers: ->
    _.difference(@get('client_ids'), @get('requested_client_ids'))

  assigningUsers: ->
    _.difference(@get('requested_client_ids'), @get('client_ids'))

  requestType: ->
    if @get('request_type') != 'adding' && @get('request_type') != 'removing'
      if @assigningUsers().length > 0 || @unassigningUsers().length > 0
        'updating'
      else
        ''
    else
      @get('request_type')
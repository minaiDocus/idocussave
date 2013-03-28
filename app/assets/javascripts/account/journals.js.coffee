Idocus.vent = _.extend({}, Backbone.Events);

Idocus.initialize = ->
  @account_journals_router = new Idocus.Routers.Account.Journals()
  Backbone.history.start()

$(document).ready ->
  Idocus.initialize()
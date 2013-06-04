Idocus.vent = _.extend({}, Backbone.Events);

Idocus.initialize = ->
  @router = new Idocus.Routers.PreAssignmentsRouter()
  Backbone.history.start()

$(document).ready ->
  Idocus.initialize()
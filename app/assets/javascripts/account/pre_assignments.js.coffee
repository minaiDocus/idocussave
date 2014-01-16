window.is_ibiza_configured = $('#pre_assignments').data().is_ibiza_configured
$('a.settings').tooltip()

Idocus.vent = _.extend({}, Backbone.Events);

Idocus.initialize = ->
  @router = new Idocus.Routers.PreAssignmentsRouter()
  Backbone.history.start()

$(document).ready ->
  Idocus.initialize()
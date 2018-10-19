window.is_ibiza_configured        = $('#pre_assignments').data().isIbizaConfigured
window.is_exact_online_configured = $('#pre_assignments').data().isExactOnlineConfigured
$('a.settings').tooltip()

Idocus.vent = _.extend({}, Backbone.Events);

Idocus.initialize = ->
  @router = new Idocus.Routers.PreAssignmentsRouter()
  Backbone.history.start()

$(document).ready ->
  Idocus.initialize()

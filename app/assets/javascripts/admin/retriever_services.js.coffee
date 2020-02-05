_require("/assets/budgea_api.js")

Idocus.vent = _.extend({}, Backbone.Events)

jQuery ->
  if $('#connectors_list').length > 0
    router = new Idocus.Routers.BudgeaConnectorsListRouter()
    Idocus.budgeaApi = new Idocus.BudgeaApi()
    Backbone.history.start()
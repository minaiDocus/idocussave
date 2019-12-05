class Idocus.Routers.BudgeaConnectorsListRouter extends Backbone.Router

  routes:
    '': 'connectors_list'

  connectors_list: (index)->
    if @list == undefined
      @list = new Idocus.Views.ConnectorsList(el: $('#connectors_list'))
    @list.render()
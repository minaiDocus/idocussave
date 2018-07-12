class Idocus.Routers.BudgeaRetrieversRouter extends Backbone.Router

  routes:
    '': 'retrievers'

  retrievers: () ->
    if @index == undefined
      @index = new Idocus.Views.RetrieversIndex(el: $('#budgea_retrievers'))
      @index.render()
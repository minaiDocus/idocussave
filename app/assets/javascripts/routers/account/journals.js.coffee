class Idocus.Routers.Account.Journals extends Backbone.Router

  routes:
    '': 'index'
  index: ->
    @index = new Idocus.Views.Account.Journals.Index (el: $('#assignment'))
    @index.render()
class Idocus.Routers.Account.Journals extends Backbone.Router

  routes:
    '': 'index'
    'journals_container': 'index'
    'users_container': 'index'

  index: ->
    @index = new Idocus.Views.Account.Journals.Index (el: $('#assignment'))
    @index.render()
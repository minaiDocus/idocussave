class Idocus.Views.PreseizureAccountsIndex extends Backbone.View

  template: JST['preseizure_accounts/index']

  initialize: (options) ->
    @packName = options.packName
    @position = options.position

    @collection = new Idocus.Collections.PreseizureAccounts()
    @collection.on 'reset', @render, this
    @collection.fetch(data: { name: @packName, position: @position })
    this

  render: ->
    @$el.html(@template(@collection))
    @setPreseizureAccounts()
    this

  setPreseizureAccounts: ->
    @collection.forEach(@addOne, this)
    this

  addOne: (item) ->
    view = new Idocus.Views.PreseizureAccountsShow(model: item)
    @$el.find('tbody').append(view.render().el)
    this

class Idocus.Views.PreseizureAccountsIndex extends Backbone.View

  template: JST['preseizure_accounts/index']

  initialize: (options) ->
    @pack_report_id = options.pack_report_id
    @preseizure_id = options.preseizure_id

    @collection = new Idocus.Collections.PreseizureAccounts()
    @collection.on 'reset', @render, this
    @collection.fetch(data: { pack_report_id: @pack_report_id, preseizure_id: @preseizure_id })
    this

  render: ->
    unit = "EUR"
    if(@collection.length > 0)
      unit = @collection.at(0).get("unit")

    @$el.html(@template({@collection, unit: unit}))
    @setPreseizureAccounts()
    this

  setPreseizureAccounts: ->
    @collection.forEach(@addOne, this)
    this

  addOne: (item) ->
    view = new Idocus.Views.PreseizureAccountsShow(model: item)
    @$el.find('tbody').append(view.render().el)
    this

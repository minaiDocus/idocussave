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
      unit = @collection.at(0).get('unit')

    @$el.html(@template({@collection, unit: unit}))
    @setPreseizureAccounts()
    @setPreseizureAccountsAnalytic()
    this

  setPreseizureAccounts: ->
    @collection.forEach(@addOne, this)
    this

  addOne: (item) ->
    view = new Idocus.Views.PreseizureAccountsShow(model: item)
    @$el.find('tbody.entries').append(view.render().el)
    this

  setPreseizureAccountsAnalytic: ->
    item = JSON.parse(@collection.at(0).get('analytic_reference'))
    if item
      @getPreTaxAmount()
      analytics = [
                    { name: item.a1_name, ventilation: item.a1_ventilation, axis1: item.a1_axis1, axis2: item.a1_axis2, axis3: item.a1_axis3 },
                    { name: item.a2_name, ventilation: item.a2_ventilation, axis1: item.a2_axis1, axis2: item.a2_axis2, axis3: item.a2_axis3 },
                    { name: item.a3_name, ventilation: item.a3_ventilation, axis1: item.a3_axis1, axis2: item.a3_axis2, axis3: item.a3_axis3 }
                  ]
      analytics.forEach(@addAnalytic, this)
    else
      @$el.find('#analytic_reference').remove()
    this

  getPreTaxAmount: ->
    @pre_tax_amount = 0
    @collection.each( (account) ->
      if account.get('type') == 2 ## Pre taxe amount type is 2 ##
        @pre_tax_amount = account.get('entries').at(0).get('amount')
    , this)

  addAnalytic: (item) ->
    if item.name
      view = new Idocus.Views.PreseizureAccountsAnalytic(item, @pre_tax_amount)
      @$el.find('tbody.analytic').append(view.render().el)
    this
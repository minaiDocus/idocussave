class Idocus.Views.PreseizureAccountsIndex extends Backbone.View

  template: JST['preseizure_accounts/index']

  initialize: (options) ->
    @pack_report_id = options.pack_report_id
    @preseizure_id = options.preseizure_id

    @collection = new Idocus.Collections.PreseizureAccounts()
    @collection.on 'reset', @setResults, this
    @collection.fetch(data: { pack_report_id: @pack_report_id, preseizure_id: @preseizure_id })
    this

  render: ->
    @$el.html(@template({@collection, unit: 'EUR'}))
    @$el.find('#tab_accounts').before('<div class="feedback float-left active" id="loading"><span class="out">Chargement en cours ...</span></div>')
    this

  setResults: ->
    @$el.find('#loading').remove()

    unit = "EUR"
    if(@collection.length > 0)
      unit = @collection.at(0).get('unit')
    @$el.find('#account_unit').html(unit)

    @setPreseizureAccounts()
    @setPreseizureAccountsAnalytic()

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
      self = this

      for i in [0..3] by 1
        references = eval("item.a#{i}_references") || null
        name       = eval("item.a#{i}_name") || null
        if references != '' && references != undefined && references != null
          references = JSON.parse(references)
          references.forEach((ref) ->
            if name != null && ref.ventilation > 0 && (ref.axis1 || ref.axis2 || ref.axis3)
              self.addAnalytic({name: name, ventilation: ref.ventilation, axis1: ref.axis1 || null, axis2: ref.axis2 || null, axis3: ref.axis3 || null})
          )
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
    view = new Idocus.Views.PreseizureAccountsAnalytic(item, @pre_tax_amount)
    @$el.find('tbody.analytic').append(view.render().el)
    this
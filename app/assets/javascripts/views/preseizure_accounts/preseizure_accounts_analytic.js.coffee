class Idocus.Views.PreseizureAccountsAnalytic extends Backbone.View

  template: JST['preseizure_accounts/analytic']

  tagName: 'tr',

  initialize: (analytic, amount) ->
    @analytic = analytic
    @amount = amount || 0
    this

  render: ->
    @$el.html(@template({ analytic: @analytic, amount: @amount }))
    this

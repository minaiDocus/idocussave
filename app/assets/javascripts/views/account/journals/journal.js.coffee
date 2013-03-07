class Idocus.Views.Account.Journals.Journal extends Backbone.View

  tagName: 'tr'
  template: JST['account/journals/journal']

  events:
    'click td': 'showUsersList'

  initialize: ->
    @model.on 'change', @render, this

  render: ->
    @$el.html(@template(model: @model))
    this

  showUsersList: ->
    Idocus.vent.trigger('showUsersList', @model)
    false
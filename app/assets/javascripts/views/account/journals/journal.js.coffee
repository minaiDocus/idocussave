class Idocus.Views.Account.Journals.Journal extends Backbone.View

  tagName: 'li'
  template: JST['account/journals/journal']

  events:
    'click a.assign': 'showUsersList'

  render: ->
    @$el.html(@template(model: @model))
    this

  showUsersList: ->
    Idocus.vent.trigger('showUsersList', @model)
    false
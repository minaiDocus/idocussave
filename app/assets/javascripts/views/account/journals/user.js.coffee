class Idocus.Views.Account.Journals.User extends Backbone.View

  tagName: 'tr'
  template: JST['account/journals/user']

  events:
    'click td': 'showJournalsList'

  render: ->
    @$el.html(@template(model: @model))
    this

  showJournalsList: ->
    Idocus.vent.trigger('showJournalsList', @model)
    false
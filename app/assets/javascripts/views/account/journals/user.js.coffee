class Idocus.Views.Account.Journals.User extends Backbone.View

  tagName: 'li'
  template: JST['account/journals/user']

  events:
    'click a.assign': 'showJournalsList'

  render: ->
    @$el.html(@template(model: @model))
    this

  showJournalsList: ->
    Idocus.vent.trigger('showJournalsList', @model)
    false
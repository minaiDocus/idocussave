class Idocus.Views.Account.Journals.User extends Backbone.View

  tagName: 'tr'
  template: JST['account/journals/user']

  events:
    'click td.selectable': 'showJournalsList'
    'mouseenter td': 'showEdit'
    'mouseleave td': 'hideEdit'

  render: ->
    @$el.html(@template(model: @model))
    this

  showJournalsList: ->
    @$el.find('input[type=radio]').attr('checked','checked')
    Idocus.vent.trigger('showJournalsList', @model)

  showEdit: ->
    @$el.find('a.edit').removeClass('hide')

  hideEdit: ->
    @$el.find('a.edit').addClass('hide')
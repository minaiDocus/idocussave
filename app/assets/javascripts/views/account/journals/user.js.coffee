class Idocus.Views.Account.Journals.User extends Backbone.View

  tagName: 'tr'
  template: JST['account/journals/user']

  events:
    'click td.selectable': 'showJournalsList'
    'mouseenter td': 'showEdit'
    'mouseleave td': 'hideEdit'

  initialize: (options) ->
    @isSelected = options.isSelected
    this

  render: ->
    @$el.html(@template(model: @model))
    @select() if @isSelected
    this

  showJournalsList: ->
    @select()
    Idocus.vent.trigger('showJournalsList', @model)

  select: ->
    @unSelectAll()
    @$el.find('input[type=radio]').attr('checked','checked')
    @$el.addClass('current')
    this

  unSelectAll: ->
    $selector = $('input[type=radio]')
    $selector.removeAttr('checked')
    $selector.parents('tr').removeClass('current')
    this

  showEdit: ->
    @$el.find('a.edit').removeClass('hide')

  hideEdit: ->
    @$el.find('a.edit').addClass('hide')
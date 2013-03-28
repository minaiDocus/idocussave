class Idocus.Views.Account.Journals.Journal extends Backbone.View

  tagName: 'tr'
  template: JST['account/journals/journal']

  events:
    'click td.selectable': 'showUsersList'
    'mouseenter td': 'showEdit'
    'mouseleave td': 'hideEdit'

  initialize: (options) ->
    @model.on 'change', @render, this
    @showDetails = options.showDetails
    @isSelected = options.isSelected
    this

  render: ->
    @$el.html(@template(model: @model, showDetails: @showDetails))
    @select() if @isSelected
    this

  showUsersList: ->
    @select()
    Idocus.vent.trigger('showUsersList', @model)

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
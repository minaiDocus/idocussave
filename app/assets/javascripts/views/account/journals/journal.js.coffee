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

  render: ->
    @$el.html(@template(model: @model, showDetails: @showDetails))
    this

  showUsersList: ->
    @$el.find('input[type=radio]').attr('checked','checked')
    Idocus.vent.trigger('showUsersList', @model)

  showEdit: ->
    @$el.find('a.edit').removeClass('hide')

  hideEdit: ->
    @$el.find('a.edit').addClass('hide')
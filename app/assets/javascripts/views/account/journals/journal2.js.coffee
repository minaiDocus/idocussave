class Idocus.Views.Account.Journals.Journal2 extends Backbone.View

  tagName: 'tr'
  template: JST['account/journals/journal2']

  events:
    'click .assigned':     'removeJournal'
    'click .unassigning':  'addJournal'
    'click .assigning':    'removeJournal'
    'click .not_assigned': 'addJournal'

  initialize: (options) ->
    @is_up = options.is_up
    @type = options.type

  render: ->
    if @is_up != undefined
      if @is_up
        direction = 'up'
      else
        direction = 'down'
    else
      direction = undefined
    @$el.html(@template(model: @model, type: @type, direction: direction))
    this

  addJournal: ->
    Idocus.vent.trigger('addJournal', @model)
    false
  removeJournal: ->
    Idocus.vent.trigger('removeJournal', @model)
    false

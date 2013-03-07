class Idocus.Views.Account.Journals.User2 extends Backbone.View

  tagName: 'tr'
  template: JST['account/journals/user2']

  events:
    'click .assigned':     'removeUser'
    'click .unassigning':  'addUser'
    'click .assigning':    'removeUser'
    'click .not_assigned': 'addUser'

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

  addUser: ->
    Idocus.vent.trigger('addUser', @model)
    false
  removeUser: ->
    Idocus.vent.trigger('removeUser', @model)
    false

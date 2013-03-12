class Idocus.Views.Account.Journals.User2 extends Backbone.View

  tagName: 'tr'
  template: JST['account/journals/user2']

  events:
    'click .assigned':     'removeUser'
    'click .not_assigned': 'addUser'

  initialize: (options) ->
    @isUp = options.isUp
    @type = options.type
    @isWaiting = options.isWaiting

  render: ->
    if @isUp != undefined
      if @isUp
        direction = 'up'
      else
        direction = 'down'
    else
      direction = undefined
    @$el.html(@template(model: @model, type: @type, direction: direction, isWaiting: @isWaiting))
    this

  addUser: ->
    Idocus.vent.trigger('addUser', @model)
    false
  removeUser: ->
    Idocus.vent.trigger('removeUser', @model)
    false

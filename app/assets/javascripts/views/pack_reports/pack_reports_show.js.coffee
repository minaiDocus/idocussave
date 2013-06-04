class Idocus.Views.PackReportsShow extends Backbone.View

  template: JST['pack_reports/show']

  tagName: 'li'

  events:
    'click a.selectable': 'select'
    'click a.deliver': 'deliver'

  render: ->
    @$el.html(@template(model: @model))
    this

  select: ->
    Idocus.vent.trigger('selectPackReport', @$el)
    this

  deliver: (e) ->
    e.preventDefault()
    @model.deliver()
    @model.set('is_delivered', true)
    @render()
    this
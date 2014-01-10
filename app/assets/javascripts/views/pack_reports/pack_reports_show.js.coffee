class Idocus.Views.PackReportsShow extends Backbone.View

  template: JST['pack_reports/show']

  tagName: 'li'

  events:
    'mouseenter a.details': 'showDetails'
    'mouseleave a.details': 'hideDetails'
    'click a.details':      'preventDefault'
    'click a.selectable':   'select'
    'click a.deliver':      'deliver'

  render: ->
    @$el.html(@template(model: @model, details: @details()))
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

  details: ->
    content = "<table class=\"table table-striped table-condensed margin0bottom\">"
    content += "<tr><td><b>Date de création du lot</b></td><td>" + @model.get('created_at') + "</td></tr>"
    content += "<tr><td><b>Date de dernière modification du lot</b></td><td>" + @model.get('updated_at') + "</td></tr>"
    content += "<tr><td><b>Date d'envoi dans Ibiza</b></td><td>"
    if @model.get('delivery_tried_at') != null
      content += @model.get('delivery_tried_at')
    content += "</td></tr>"
    content += "<tr><td colspan=\"2\"><b>Message retour Ibiza (si erreur) :</b><br>"
    if @model.get('delivery_message') != null
      content += @model.get('delivery_message')
    content += "</td></tr>"
    content += "</table>"
    content

  showDetails: (e) ->
    this.$('.details').popover('show');

  hideDetails: (e) ->
    this.$('.details').popover('hide');

  preventDefault: (e) ->
    e.preventDefault()

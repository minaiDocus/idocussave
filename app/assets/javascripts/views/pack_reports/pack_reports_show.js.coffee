class Idocus.Views.PackReportsShow extends Backbone.View

  template: JST['pack_reports/show']

  tagName: 'li'

  events:
    'mouseenter a.details': 'showDetails'
    'mouseleave a.details': 'hideDetails'
    'mouseenter a.tip':     'showTip'
    'mouseleave a.tip':     'hideTip'
    'click a.details':      'preventDefault'
    'click a.selectable':   'select'
    'click a.deliver':      'deliver'

  initialize: (options) ->
    @view = options.view || 'all'
    @query = options.query || ''
    this

  render: ->
    @$el.html(@template(view: @view, query: @query, model: @model, details: @details()))
    this

  select: ->
    Idocus.vent.trigger('selectPackReport', @$el)
    this

  deliver: (e) ->
    e.preventDefault()
    if confirm("Vous êtes sur le point d'envoyer des écritures dans #{@model.get('user_software')}. Etes-vous sûr ?")
      $(e.currentTarget).tooltip('hide')
      @model.deliver()
      @model.set('is_delivered_to', @model.get('user_software').toLowerCase().replace(/[ ]/g, '_'))
      @render()
    this

  details: ->
    content = "<table class=\"table table-striped table-condensed margin0bottom\">"
    content += "<tr><td><b>Date d'ajout de la première écriture :</b></td><td>" + @model.get('created_at') + "</td></tr>"
    content += "<tr><td><b>Date d'ajout de la dernière écriture :</b></td><td>" + @model.get('last_preseizure_at') + "</td></tr>"
    if @model.get('user_software')
      content += "<tr><td><b>Date du dernier envoi [#{@model.get('user_software')}] :</b></td><td>"
      if @model.get('delivery_tried_at') != null
        content += @model.get('delivery_tried_at')
      content += "</td></tr>"
      content += "<tr><td colspan=\"2\"><b>Message d'erreur d'envoi [#{@model.get('user_software')}] :</b><br>"
      if @model.delivery_message() != null
        content += @model.delivery_message().replace(/</g, '&lt;').replace(/>/g, '&gt;')
      content += "</td></tr>"
    content += "</table>"
    content

  showDetails: (e) ->
    this.$('.details').popover('show')

  hideDetails: (e) ->
    this.$('.details').popover('hide')

  preventDefault: (e) ->
    e.preventDefault()

  showTip: (e) ->
    $(e.currentTarget).tooltip('show')

  hideTip: (e) ->
    $(e.currentTarget).tooltip('hide')

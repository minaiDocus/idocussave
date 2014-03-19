class Idocus.Views.PreseizuresShow extends Backbone.View

  template: JST['preseizures/show']
  tagName: 'li'
  className: 'piece'

  events:
    'mouseenter a.details': 'showDetails'
    'mouseleave a.details': 'hideDetails'
    'mouseenter a.tip':     'showTip'
    'mouseleave a.tip':     'hideTip'
    'click a.details':      'preventDefault'
    'click a.selectable':   'select'
    'click a.edit':         'edit'
    'click a.deliver':      'deliver'

  initialize: (options) ->
    @packName = options.packName
    @model.on 'change', @render, this
    this

  render: ->
    @$el.html(@template(model: @model, packName: @packName, details: @details()))
    this

  select: ->
    Idocus.vent.trigger('selectPreseizure', @$el)
    this

  edit: (e) ->
    e.preventDefault()
    form = new Backbone.Form(model: @model).render()
    title = "Edition de la pièce #{("000" + @model.get('position')).slice(-3)}"
    bootstrapModal = new Backbone.BootstrapModal(title: title, okText: 'Valider', cancelText: 'Annuler', content: form)
    bootstrapModal.on "ok", ->
      form.commit()
      form.model.save()
    bootstrapModal.open()
    this

  deliver: (e) ->
    e.preventDefault()
    if confirm("Vous êtes sur le point d'envoyer des écritures dans Ibiza. Etes-vous sûr ?")
      $(e.currentTarget).tooltip('hide')
      @model.deliver()
      @model.set('is_delivered', true)
      @render()
    this

  details: ->
    content = "<table class=\"table table-striped table-condensed margin0bottom\">"
    content += "<tr><td><b>Date de création :</b></td><td>" + @model.get('created_at') + "</td></tr>"
    content += "<tr><td><b>Date de modification :</b></td><td>" + @model.get('updated_at') + "</td></tr>"
    if window.is_ibiza_configured
      content += "<tr><td><b>Date du dernier envoi dans Ibiza :</b></td><td>"
      if @model.get('delivery_tried_at') != null
        content += @model.get('delivery_tried_at')
      content += "</td></tr>"
      content += "<tr><td colspan=\"2\"><b>Message d'erreur d'envoi dans Ibiza :</b><br>"
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

  showTip: (e) ->
    $(e.currentTarget).tooltip('show')

  hideTip: (e) ->
    $(e.currentTarget).tooltip('hide')

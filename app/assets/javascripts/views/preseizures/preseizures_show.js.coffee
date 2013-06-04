class Idocus.Views.PreseizuresShow extends Backbone.View

  template: JST['preseizures/show']
  tagName: 'li'
  className: 'piece'

  events:
    'click a.selectable': 'select'
    'click a.edit': 'edit'
    'click a.deliver': 'deliver'

  initialize: (options) ->
    @packName = options.packName
    @model.on 'change', @render, this
    this

  render: ->
    @$el.html(@template(model: @model, packName: @packName))
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
    @model.deliver()
    @model.set('is_delivered', true)
    @render()
    this
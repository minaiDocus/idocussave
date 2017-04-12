class Idocus.Views.PreseizureAccountsShow extends Backbone.View

  template: JST['preseizure_accounts/show']

  tagName: 'tr'

  events:
    'mouseenter a.tip':   'showTip'
    'mouseleave a.tip':   'hideTip'
    'click a.edit':       'edit'
    'click a.edit_entry': 'edit_entry'

  initialize: ->
    @model.on 'change', @render, this
    @model.get('entries').on 'change', @render, this
    this

  render: ->
    @$el.html(@template(model: @model))
    this

  edit: (e) ->
    e.preventDefault()
    form = new Backbone.Form(model: @model).render()
    title = "Edition d'une écriture"
    bootstrapModal = new Backbone.BootstrapModal(title: title, okText: 'Valider', cancelText: 'Annuler', content: form)
    bootstrapModal.on "ok", ->
      form.commit()
      form.model.save()
    bootstrapModal.open()
    this

  edit_entry: (e) ->
    e.preventDefault()
    id = $(e.target).parents('a').data('id')
    entry = @model.get('entries').where(id: id.toString())[0]
    form = new Backbone.Form(model: entry).render()
    form.parentModel = @model
    title = "Edition d'une écriture"
    bootstrapModal = new Backbone.BootstrapModal(title: title, okText: 'Valider', cancelText: 'Annuler', content: form)
    bootstrapModal.on "ok", ->
      error = form.commit()
      if typeof error != 'undefined'
        this.preventClose()
      else
        form.parentModel.save()
    bootstrapModal.open()
    $(form.el).submit(-> false)
    this

  showTip: (e) ->
    $(e.currentTarget).tooltip('show')

  hideTip: (e) ->
    $(e.currentTarget).tooltip('hide')

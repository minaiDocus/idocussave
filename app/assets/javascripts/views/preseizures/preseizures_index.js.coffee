class Idocus.Views.PreseizuresIndex extends Backbone.View

  template: JST['preseizures/index']
  paginator: JST['paginator']

  initialize: (options) ->
    @view = options.view || 'all'
    @packName = options.packName
    @page = options.page || 1

    _.bindAll(this, "selectPreseizure")
    Idocus.vent.bind("selectPreseizure", @selectPreseizure)

    @collection = new Idocus.Collections.Preseizures()
    @collection.on 'reset', @render, this
    @collection.fetch(data: { name: @packName, page: @page, view: @view })
    this

  render: ->
    @$el.html(@template(@collection))
    @setPreseizures()
    if @collection.total > @collection.perPage
      @paginate()
    this

  setPreseizures: ->
    @collection.forEach(@addOne, this)
    this

  addOne: (item) ->
    view = new Idocus.Views.PreseizuresShow(model: item, view: @view, packName: @packName)
    @$el.children('ul').append(view.render().el)
    this

  paginate: ->
    prefix = "#{@view}/#{@packName}/"
    @$el.append(@paginator(collection: @collection, prefix: prefix))
    this

  selectPreseizure: (view) ->
    @$el.find('li').removeClass('active')
    view.addClass('active')
    this

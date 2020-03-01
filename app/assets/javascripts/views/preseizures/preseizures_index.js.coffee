class Idocus.Views.PreseizuresIndex extends Backbone.View

  template: JST['preseizures/index']
  paginator: JST['paginator']

  initialize: (options) ->
    @view = options.view || 'all'
    @query = options.query || ''
    @pack_report_id = options.pack_report_id
    @page = options.page || 1

    _.bindAll(this, "selectPreseizure")
    Idocus.vent.bind("selectPreseizure", @selectPreseizure)

    @collection = new Idocus.Collections.Preseizures()
    @collection.on 'reset', @setPreseizures, this
    @collection.fetch(data: { pack_report_id: @pack_report_id, page: @page, view: @view, filter: @query })
    this

  render: ->
    @$el.html(@template(@collection))
    @$el.children('ul').prepend('<div class="feedback float-left active" id="loading"><span class="out">Chargement en cours ...</span></div>')
    this

  setPreseizures: ->
    @$el.children('ul').html('')
    @collection.forEach(@addOne, this)
    if @collection.total > @collection.perPage
      @paginate()
    this

  addOne: (item) ->
    view = new Idocus.Views.PreseizuresShow(model: item, view: @view, pack_report_id: @pack_report_id)
    @$el.children('ul').append(view.render().el)
    this

  paginate: ->
    if @query != ''
      prefix = "#{@view}/#{@pack_report_id}/search/#{@query}/"
    else
      prefix = "#{@view}/#{@pack_report_id}/"
    @$el.append(@paginator(collection: @collection, prefix: prefix))
    this

  selectPreseizure: (view) ->
    @$el.find('li').removeClass('active')
    view.addClass('active')
    this

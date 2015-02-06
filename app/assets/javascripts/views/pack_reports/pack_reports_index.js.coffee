class Idocus.Views.PackReportsIndex extends Backbone.View

  template: JST['pack_reports/index']
  paginator: JST['paginator']

  events:
    'click .remove_search': 'remove_search'
    'keypress input[name=pack_reports_search]': 'search'
    'change select[name=view]': 'filter_by_view'

  initialize: (options) ->
    @query = null
    @page = options.page || 1
    @view = options.view || 'all'

    _.bindAll(this, "selectPackReport")
    Idocus.vent.bind("selectPackReport", @selectPackReport)

    @collection = new Idocus.Collections.PackReports()
    @collection.on 'reset', @setPackReports, this
    this

  render: ->
    @$el.html(@template(@collection))
    @setPackReports()
    @$el.find('select[name=view]').val(@view)
    this

  setPackReports: ->
    @$el.children('ul').html('')
    @collection.forEach(@addOne, this)
    @paginate()
    this

  addOne: (item) ->
    view = new Idocus.Views.PackReportsShow(model: item, view: @view)
    @$el.children('ul').append(view.render().el)
    this

  paginate: ->
    @$el.find('.pagination').remove()
    if @query != null
      prefix = "#{@view}/search/#{@query}/"
    else
      prefix = "#{@view}/"
    if @collection.total > @collection.perPage
      @$el.append(@paginator(collection: @collection, prefix: prefix))
    this

  selectPackReport: (view) ->
    @$el.find('li').removeClass('active')
    view.addClass('active')
    this

  update: (view, query, page) ->
    @view = view || 'all'
    @query = query || null
    @page = page || 1
    data = { view: @view, page: @page }
    if @query != null
      data['name'] = @query
      @collection
    @collection.fetch(data: data)
    this

  remove_search: ->
    @$el.find('input[name=pack_reports_search]').val('')
    view = @$el.find('select[name=view]').val() || 'all'
    Backbone.history.navigate("#{view}", true)
    this

  search: (e) ->
    if e == undefined || (e != undefined && e.keyCode == 13)
      view = @$el.find('select[name=view]').val() || 'all'
      query = @$el.find('input[name=pack_reports_search]').val()
      Backbone.history.navigate("#{view}/search/#{query}")
      this

  filter_by_view: ->
    view = @$el.find('select[name=view]').val()
    query = @$el.find('input[name=pack_reports_search]').val()
    Backbone.history.navigate("#{view}/search/#{query}")
    this

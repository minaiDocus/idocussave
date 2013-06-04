class Idocus.Views.PackReportsIndex extends Backbone.View

  template: JST['pack_reports/index']
  paginator: JST['paginator']

  events:
    'keypress input[name=pack_reports_search]': 'search'

  initialize: (options) ->
    @query = null
    @page = options.page || 1

    _.bindAll(this, "selectPackReport")
    Idocus.vent.bind("selectPackReport", @selectPackReport)

    @collection = new Idocus.Collections.PackReports()
    @collection.on 'reset', @setPackReports, this
    this

  render: ->
    @$el.html(@template(@collection))
    @setPackReports()
    this

  setPackReports: ->
    @$el.children('ul').html('')
    @collection.forEach(@addOne, this)
    @paginate()
    this

  addOne: (item) ->
    view = new Idocus.Views.PackReportsShow(model: item)
    @$el.children('ul').append(view.render().el)
    this

  paginate: ->
    @$el.find('.pagination').remove()
    if @query != null
      prefix = "search/#{@query}/"
    else
      prefix = ""
    if @collection.total > @collection.perPage
      @$el.append(@paginator(collection: @collection, prefix: prefix))
    this

  selectPackReport: (view) ->
    @$el.find('li').removeClass('active')
    view.addClass('active')
    this

  update: (query, page) ->
    @query = query || null
    @page = page || 1
    data = { page: @page }
    if @query != null
      data['name'] = @query
      @collection
    @collection.fetch(data: data)
    this

  search: (e) ->
    if e == undefined || (e != undefined && e.keyCode == 13)
      query = @$el.find('input[name=pack_reports_search]').val()
      Backbone.history.navigate("#search/#{query}", true)
      this
class Idocus.Views.ConnectorsList extends Backbone.View

  template: JST['retrievers/connectors_list']

  events:
    'click .index_filter': 'filter'

  initialize: (options) ->
    @common = new Idocus.Models.Common()
    @providers_filtered = @banks_filtered = []
    @loading = true
    @active_index = ''
    @fetch_connectors()
    this

  render: ->
    @$el.html(@template(loading: @loading, providers: @providers_filtered, banks: @banks_filtered, active: @active_index))
    this

  fetch_connectors: ()->
    self = this
    @connectors  = new Idocus.Collections.Connectors()
    @connectors.on 'reset', ()-> self.filter_connectors()

    @connectors.fetch_all().then(
      null
      (error)->
        self.render()
        alert(error)
    )

  filter: (e)->
    if !@loading
      filter_index = $(e.target).attr('data-filter')
      @active_index = filter_index
      @filter_connectors(filter_index)

  filter_connectors: (filter)->
    @loading = false
    @providers_filtered = @connectors.find("capabilities", "include", 'document')
    @banks_filtered = @connectors.find("capabilities", "include", 'bank')

    if filter != undefined && filter != null && filter != ''
      @providers_filtered = @filter_collection(@providers_filtered, filter)
      @banks_filtered = @filter_collection(@banks_filtered, filter)

    @providers_filtered.sort(@common.sort_array_models_by("name")).reverse()
    @banks_filtered.sort(@common.sort_array_models_by("name")).reverse()

    @render()
    this

  filter_collection: (connectors, filter)->
    result = []
    for connector in connectors
      if eval("/^#{filter}/i.test(\"#{connector.get('name').replace(/\"/g, '')}\")")
        result.push(connector)
    result
class Idocus.Views.RetrieversIndex extends Backbone.View

  template: JST['retrievers/index']

  events:
    'keyup #retriever_connector_name': 'filter_connectors'
    'change #retriever_connections_list': 'load_connector'
    'click .filter_type': 'filter_by_connector_type'

  initialize: (options) ->
    @common = new Idocus.Models.Common()
    @loading = true
    Idocus.new_connector = if $('#retriever_budgea_id').val() then false else true
    @fetch_connectors()
    this

  render: ->
    @$el.html(@template(loading: @loading, list_url: "#{location.protocol}//#{location.host}/account/retrievers/list", new_connector: Idocus.new_connector))
    custom_checkbox_buttons()
    @hide_banks_if_bridge()
    this

  fetch_connectors: ->
    self = this
    @connectors  = new Idocus.Collections.Connectors()
    @connectors.on('reset', ()->
      self.loading = false
      self.render()
      if self.connectors.models.length > 0
        self.connectors_filtered = self.connectors.models
        self.update_connector_list()
        connector_id = $('#retriever_connector_id').val()
        if connector_id > 0
          self.get_connector(connector_id)
    )

    @connectors.fetch_all().then(
      null
      (error)->
        self.loading = false
        self.render()
    )

  filter_connectors: ->
    self = this
    self.connectors_filtered = []
    setTimeout(() ->
      filter_name = self.$el.find('#retriever_connector_name').val()
      if filter_name != ""
        self.connectors_filtered = self.connectors.find("name", "contain", filter_name)
      else
        self.connectors_filtered = self.connectors.models

      self.update_connector_list()
    , 700)

  filter_by_connector_type: ->
    @connectors_filtered = connectors_filtered_bank = connectors_filtered_document = []
    if @$el.find('#check_banks').is(':checked') && !$('#budgea_sync').hasClass('bridge')
      connectors_filtered_bank = @connectors.find("capabilities", "include", 'bank')
    if @$el.find('#check_document').is(':checked')
      connectors_filtered_document = @connectors.find("capabilities", "include", 'document')

    @connectors_filtered = Array.from(new Set(connectors_filtered_document.concat(connectors_filtered_bank)))
    @update_connector_list()

  update_connector_list: ->
    options = ""

    @connectors_filtered.sort(@common.sort_array_models_by("name")).reverse()
    for connector in @connectors_filtered
      options += "<option value='" + connector.get("id") + "'>" + connector.get("name") + "</option>"

    @$el.find("#retriever_connections_list").html(options)
    @$el.find("#connectors_count").html(@connectors_filtered.length)

  load_connector: ->
    connector_id = @$el.find('#retriever_connections_list').val()
    @get_connector(connector_id)

  get_connector: (connector_id) ->
    @model = @connectors.find("id", "is", connector_id)[0]
    @$el.find('#retriever_connector_name').val(@model.get("name"))
    @$el.find('#retriever_connector_urls').html(@model.parse_urls())
    @$el.find("#retriever_connections_list option[value=#{connector_id}]").prop('selected', true)

    if @step1_view == undefined
      @step1_view = new Idocus.Views.RetrieversStep1(el: $('#budgea_information_fields'))

    @step1_view.load_connector(@model)
    @step1_view.render()

  hide_banks_if_bridge: ->
    if $('#budgea_sync').hasClass('bridge')
      $('#banks_label').remove()
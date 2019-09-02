class Idocus.Views.RetrieversStep2 extends Backbone.View

  template: JST['retrievers/step2']

  events:
    'click #retriever_additionnal_commit': 'submit_additionnal_infos'

  initialize: (options) ->
    @common = new Idocus.Models.Common()
    this

  generate_additionnal_fields: (info, fields) ->
    @connector_info = info
    @html = @common.fields_constructor(fields)
    @render()

  render: () ->
    @$el.html(@template(html_fields: @html))
    this

  submit_additionnal_infos: ()->
    self = this
    if @common.valid_fields(@$el)
      @common.action_loading(@$el, true)

      data_local = { budgea_id: @connector_info.id }
      data_remote = @common.serialize_form_json( @$el.find('#additionnal_fields') )

      Idocus.budgeaApi.update_additionnal_infos(@connector_info.id, data_remote, data_local).then(
        ()->
          self.common.go_to_step3( self.connector_info )
        (error)->
          self.common.action_loading(self.$el, false)
          self.$el.find('#information').html("<div class='alert alert-danger'>#{error}</div>")
      )
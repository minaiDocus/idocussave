class Idocus.Views.RetrieversStep1 extends Backbone.View

  template: JST['retrievers/step1']

  events:
    'click #retriever_commit': 'create_connector'

  initialize: (options) ->
    @common = new Idocus.Models.Common()
    this

  load_connector: (connector)->
    @connector = connector
    this

  render: ()->
    @$el.html(@template( connector: @connector, budgea_id: $('#retriever_budgea_id').val() ))
    this

  create_connector: ()->
    self = this
    if @common.valid_fields(@$el)
      @common.action_loading(@$el, true)

      id_connection = $('#retriever_budgea_id').val() || 0

      data_remote = @common.serialize_form_json( @$el.find('#connector_fields') )
      delete data_remote.ido_custom_name
      delete data_remote.ido_journal

      if id_connection == 0
        capabilities = @$el.find('#field_ido_capabilities').val().split('_')
        if capabilities.includes('document')
          Object.assign(data_remote, data_remote, { id_provider: @$el.find('#ido_connector_id').val() })
        else
          Object.assign(data_remote, data_remote, { id_bank: @$el.find('#ido_connector_id').val() })
      else
        delete data_remote.website

      data_local = @common.serialize_form_json( @$el.find('#ido_form') )
      Object.assign(data_local, data_local, { ido_journal: @$el.find('#field_ido_journal').val(), ido_custom_name: @$el.find('#field_ido_custom_name').val() })

      Idocus.budgeaApi.create_or_update_connection(id_connection, data_remote, data_local).then(
        (data)->
          self.common.action_loading(self.$el, false)

          #####TEST###
          #Object.assign(data.remote_response, data.remote_response, { additionnal_fields: [{"regex": null, "type": "text", "name": "security_code", "value": null, "label": "Enter your 6-digit code"}] })
          ############
          if data.remote_response.fields != '' && data.remote_response.fields != undefined && data.remote_response.fields != null
            Object.assign(data.remote_response, data.remote_response, {additionnal_fields: data.remote_response.fields})

          if data.remote_response.additionnal_fields != '' && data.remote_response.additionnal_fields != undefined && data.remote_response.additionnal_fields != null
            self.common.go_to_step2( data.remote_response )
          else
            self.common.go_to_step3( data.remote_response )
          self.$el.find('#information').html("<div class='alert alert-success'>Edition terminer</div>")
        (error)->
          self.common.action_loading(self.$el, false)
          self.$el.find('#information').html("<div class='alert alert-danger'>#{error}</div>")
      )
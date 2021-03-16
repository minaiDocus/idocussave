class Idocus.Views.RetrieversStep1 extends Backbone.View

  template: JST['retrievers/step1']

  events:
    'change .field_website': 'check_field_website'
    'click #retriever_commit': 'create_connector'

  initialize: (options) ->
    @id_connection = $('#retriever_budgea_id').val() || 0
    @common = new Idocus.Models.Common()
    this

  load_connector: (connector)->
    @connector = connector
    @contact_fields = false
    this

  render: ()->
    @$el.html(@template( connector: @connector, budgea_id: @id_connection ))
    if @id_connection > 0 && $('#retriever_skip_step1').val() > 0
      @remove_required_field()
      @$el.find('.form-group').addClass('hide')
      @create_connector() #Simulate the validation click to go to the next step
    this

  remove_required_field: ()->
    @$el.find('.form-group').removeClass('required')
    @$el.find('.form-group .control-section .field ').removeClass('required')

  check_field_website: (e)->
    value = $(e.target).val()
    if value == 'pro'
      $('#connector_fields #contact_fields').slideDown('fast')
      $('#connector_fields .contact_fields').addClass('required')
      @connector.set_contact_values()
      @contact_fields = true
    else
      $('#connector_fields #contact_fields').slideUp('fast')
      $('#connector_fields .contact_fields').removeClass('required')
      @contact_fields = false
    this

  create_connector: ()->
    self = this
    if @common.valid_fields(@$el)
      oauth_presence = @$el.find('.oauth').val()

      if oauth_presence
        if @id_connection > 0
          Idocus.budgeaApi.webauth(@id_connection, false)
        else
          Idocus.budgeaApi.webauth(@connector.get('id'), true)
      else
        @common.action_loading(@$el, true)

        data_remote = @common.serialize_form_json( @$el.find('#connector_fields') )
        delete data_remote.ido_custom_name
        delete data_remote.ido_journal

        data_contact = {}
        if @contact_fields
          data_contact =  {
                            first_name:   data_remote.contact_field_first_name,
                            name:         data_remote.contact_field_name,
                            society:      data_remote.contact_field_society,
                          }
        delete data_remote.contact_fields_first_name
        delete data_remote.contact_field_name
        delete data_remote.contact_field_society

        if @id_connection == 0
          capabilities = @$el.find('#field_ido_capabilities').val().split('_')
          if capabilities.includes('document')
            Object.assign(data_remote, data_remote, { id_provider: @$el.find('#ido_connector_id').val() })
          else
            Object.assign(data_remote, data_remote, { id_bank: @$el.find('#ido_connector_id').val() })
        #else
          #delete data_remote.website

        data_local = @common.serialize_form_json( @$el.find('#ido_form') )
        Object.assign(data_local, data_local, { ido_journal: @$el.find('#field_ido_journal').val(), ido_custom_name: @$el.find('#field_ido_custom_name').val() })

        fetch_connection = ()->
          Idocus.budgeaApi.create_or_update_connection(self.id_connection, data_remote, data_local).then(
            (data)->
              self.common.action_loading(self.$el, false)

              if (data.remote_response.fields != '' && data.remote_response.fields != undefined && data.remote_response.fields != null) && (data.remote_response.additionnal_fields == '' || data.remote_response.additionnal_fields == undefined || data.remote_response.additionnal_fields == null)
                Object.assign(data.remote_response, data.remote_response, {additionnal_fields: data.remote_response.fields})

              if data.remote_response.additionnal_fields != '' && data.remote_response.additionnal_fields != undefined && data.remote_response.additionnal_fields != null
                self.common.go_to_step2( data.remote_response )
              else
                self.common.go_to_step3( data.remote_response )
            (error)->
              self.common.action_loading(self.$el, false)
              self.$el.find('.form-group').removeClass('hide')
              self.$el.find('#information').html("<div class='alert alert-danger'>#{error}</div>")
          )

        if @contact_fields
          Idocus.budgeaApi.update_contact(data_contact).then(
            (data) -> fetch_connection()
            (error)->
              self.common.action_loading(self.$el, false)
              self.$el.find('.form-group').removeClass('hide')
              self.$el.find('#information').html("<div class='alert alert-danger'>#{error}</div>")
          )
        else
          fetch_connection()
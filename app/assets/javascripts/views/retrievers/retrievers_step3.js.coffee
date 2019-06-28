class Idocus.Views.RetrieversStep3 extends Backbone.View

  template: JST['retrievers/step3']

  events:
    'click #master_checkbox': 'select_all_accounts'
    'click #retriever_selection_commit': 'submit_selected_accounts'

  initialize: (options) ->
    @common = new Idocus.Models.Common()
    @accounts = new Idocus.Collections.Accounts
    @loading = true
    this

  load_connector_info: (info) ->
    @connector_info = info
    @fetch_accounts()
    this

  render: () ->
    @$el.html(@template(loading: @loading, accounts: @accounts.models, my_accounts: @accounts.my_accounts))
    this

  fetch_accounts: () ->
    self = this
    @accounts.fetch_accounts_of(@connector_info.id).then(
      ()->
        self.loading = false
        self.render()
      (error)->
        self.$el.find('#information').html("<div class='alert alert-danger'>"+error+"</div>")
    )

  select_all_accounts: () ->
    if @$el.find('#master_checkbox').is(':checked')
      @$el.find('.checkbox').prop('checked', true)
    else
      @$el.find('.checkbox').prop('checked', false)

  submit_selected_accounts: () ->
    if confirm('Etes vous sûr?')
      self = this
      @common.action_loading(@$el, true)

      data = @common.serialize_form_json( @$el.find('#accounts_selection') )
      accounts = []
      for account_id in (data.accounts || [])
        account = @accounts.find('id', 'is', account_id)
        if account.length > 0
          accounts.push(account[0].attributes)

      Idocus.budgeaApi.update_my_accounts(accounts).then(
        ()->
          self.common.action_loading(self.$el, false)
          location.href = "#{Idocus.budgeaApi.local_host}/account/retrievers/new?create=1"
        (error)->
          self.common.action_loading(self.$el, false)
          self.$el.find('#information').html("<div class='alert alert-danger'>#{error}</div>")
      )
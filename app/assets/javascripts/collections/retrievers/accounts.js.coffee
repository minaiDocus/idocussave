class Idocus.Collections.Accounts extends Backbone.Collection
  model: Idocus.Models.Account

  initialize: ()->
    @my_accounts = []

  fetch_accounts_of: (connector_id)->
    self = this
    promise = new Promise((resolve, reject)->
      Idocus.budgeaApi.get_accounts_of(connector_id).then(
        (data)->
          self.reset(data.remote_accounts)
          self.my_accounts = data.my_accounts
          resolve()
        (error)-> reject(error)
      )
    )

  parse: (response) ->
    response.accounts

  find: (field, operator, pattern) ->
    result = []

    for account in @models
      value = account.get(field)
      reg = new RegExp(pattern,"i")

      if operator == "is" && String(value) == String(pattern)
        result.push(account)
      else if operator == "contain" && reg.test(value)
        result.push(account)

    result
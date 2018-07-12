class Idocus.Collections.Connectors extends Backbone.Collection
  model: Idocus.Models.Connector

  initialize: ()->
    @common = new Idocus.Models.Common()

  parse: (response) ->
    response.connectors

  fetch_all: ()->
    self = this
    promise = new Promise((resolve, reject)->
      connectors_cache = self.common.getCache('connectors')
      if connectors_cache != ''
        setTimeout(
          ()->
            self.reset(connectors_cache)
            resolve()
          1500
        )
      else
        Idocus.budgeaApi.get_connectors().then(
          (datas)-> 
            self.common.setCache('connectors', datas, 15)
            self.reset(datas)
            resolve()
          (error)-> reject(error)
        )
    )

  find: (field, operator, pattern) ->
    result = []

    for connector in @models
      value = connector.get(field)
      reg = new RegExp(pattern,"i")

      if operator == "is" && String(value) == String(pattern)
        result.push(connector)
      else if operator == "contain" && reg.test(value)
        result.push(connector)
      else if operator == "include" && value.includes(pattern)
        result.push(connector)

    result
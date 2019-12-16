class Idocus.Collections.Connectors extends Backbone.Collection
  model: Idocus.Models.Connector

  initialize: ()->
    @common = new Idocus.Models.Common()

  parse: (response) ->
    response.connectors

  fetch_all: ()->
    self = this
    promise = new Promise((resolve, reject)->
      connectors_cache = self.common.getCache('connectors') || []

      # 1 times out of 2, connectors fetcher get different connector's count
      #Temporary fix : Set in cache | Get, the maximum connectors fetched
      Idocus.budgeaApi.get_connectors().then(
        (datas)->
          if connectors_cache.length < datas.length
            self.common.setCache('connectors', datas, 15)
            console.log('datas')
            self.reset(datas)
          else
            self.common.setCache('connectors', connectors_cache, 15)
            console.log('cache')
            self.reset(connectors_cache)
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
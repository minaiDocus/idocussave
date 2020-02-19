class Idocus.Collections.Connectors extends Backbone.Collection
  model: Idocus.Models.Connector

  initialize: ()->
    @common = new Idocus.Models.Common()
    @connectors_cache = []
    @connectors_fetched = []
    @retries_limit = 8

  parse: (response) ->
    response.connectors

  fetch_all: ()->
    self = this
    promise = new Promise((resolve, reject)->
      self.connectors_cache = self.common.getCache('connectors') || []

      # 1 times out of 2, connectors fetcher get different connector's count
      #Temporary fix : Set in cache | Get, the maximum connectors fetched from get_connectors function
      self.get_connectors(0).then(
        (datas)->
          console.log("Use : " + self.connectors_fetched.length)
          self.common.setCache('connectors', self.connectors_fetched, 15)
          self.reset(self.connectors_fetched)
          resolve()
        (error)-> reject(error)
      )
    )

  get_connectors: (retry)->
    self = this
    console.log("Try : " + retry)

    promise = new Promise((resolve, reject) ->
      if retry >= self.retries_limit
        console.log 'limit reached'
        self.connectors_fetched = self.connectors_cache
        resolve()
      else
        Idocus.budgeaApi.get_connectors().then(
          (datas)->
            fetched_length = datas.length
            console.log("fetched : " + fetched_length)

            if self.connectors_cache.length <= fetched_length
              if fetched_length < 300
                self.connectors_cache = datas
                self.get_connectors(retry + 1).then(
                  (d)-> resolve()
                  (e)-> reject(e)
                )
              else
                console.log 'using-fetched'
                self.connectors_fetched = datas
                resolve()
            else
              if self.connectors_cache < 300
                self.get_connectors(retry + 1).then(
                  (d)-> resolve()
                  (e)-> reject(e)
                )
              else
                console.log 'using-cached'
                self.connectors_fetched = self.connectors_cache
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
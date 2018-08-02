_require("/assets/jose.js")

class Idocus.BudgeaApi
  constructor: ()->
    @encryptor = null
    @local_host = "#{location.protocol}//#{location.host}"
    config = ''
    if $('#retriever_budgea_config').length > 0
      config = JSON.parse( atob($('#retriever_budgea_config').val()) )
      $('#retriever_budgea_config').remove()

    if config == undefined || config == '' || config == null
      alert('Erreur de chargement de la page!')
    else
      @api_base_url = config.url
      @api_client_id = config.c_id
      @api_client_secret = config.c_ps
      @api_ky = {}
      if config.c_ky != undefined && config.c_ky != ''
        @api_ky = JSON.parse( atob(config.c_ky) )
        @init_encryptor()

  init_for_user: ()->
    self = this
    @get_user_tokens()
    @check_cgu()
    $('#cgu_bi_validate').on('click', ()-> self.validate_cgu(self) )

  set_tokens: (options)->
    @user_token = options.user_token
    @bi_token = options.bi_token

  get_user_tokens: ()->
    @user_token = $('#retriever_user_token').val() || ''
    @bi_token = $('#retriever_bi_token').val() || ''
    $('#retriever_user_token').remove()
    $('#retriever_bi_token').remove()

  check_cgu: ()->
    self = this
    got_error = (error)->
      alert(error)
      location.href = "#{self.local_host}/account/retrievers"

    not_registered = false
    if @bi_token.length == 0
      not_registered = true
    else
      @remote_fetch({
        url: "/users/me/terms"
        type: "GET"
        onError:(error)-> got_error(error)
        onSuccess: (data)->
          if data.to_sign == undefined || data.to_sign == '' || data.to_sign == null
            not_registered = true
          else
            self.init_or_create_user()
      })

    if not_registered
      @remote_fetch({
        url: "/terms"
        type: "GET"
        onError: (error)-> got_error(error)
        onSuccess: (data)->
          self.cgu_id = data.terms.id
          self.cgu_version = data.terms.version
          content = data.content.replace(/\n/g, "<br>")
          $('#terms').html("<p>#{content}</p>")
          $('#showCguBI').modal()
      })

  validate_cgu: (self)->
    $("#showCguBI .feedback").addClass('active')
    callback = ()->
      self.remote_fetch({
        url: '/users/me/terms'
        type: 'POST'
        data: {id_terms: self.cgu_id}
        onError: (error)->
          alert(error)
          $("#showCguBI .feedback").removeClass('active')
        onSuccess: (remote_data, local_data)-> $('#showCguBI').modal('hide')
      })

    self.init_or_create_user().then(callback)

  init_or_create_user: ()->
    self = this
    got_error = (error)->
      alert(error)
      location.href = "#{self.local_host}/account/retrievers"

    promise = new Promise((resolve, reject)->
      if self.bi_token.length == 0
        self.remote_fetch({
          url: '/auth/init'
          use_secrets: true
          type: 'POST'
          onError: (error)-> got_error(error)
          onSuccess: (data)->
            self.bi_token = data.auth_token
            if data.type == 'permanent'
              self.double_fetch({
                remote: { url: "/users/me/profiles", type: 'GET', collection: 'profiles' }
                local: { url: "/retriever/create_budgea_user", data: {auth_token: data.auth_token} }
                onError: (error)-> got_error(error)
                onSuccess: (remote_data, local_data)-> resolve()
              })
            else
              got_error('Impossible de créer un compte budget insight')
        })
      else
        resolve()
    )

  get_accounts_of: (connector_id) ->
    self = this
    remote_accounts = []
    my_accounts = []
    promise = new Promise((resolve, reject)->
      self.double_fetch({
        remote: { url: '/users/me/connections?expand=all_accounts', type: 'GET', collection: 'connections' }
        local: { url: '/retriever/get_my_accounts', data: {connector_id: connector_id} }
        onSuccess: (remote_response, local_response)->
          ### Respond to remote response ###
          for account in remote_response
            if account.id == connector_id
              remote_accounts = account.all_accounts

          ### Respond to local response ###
          my_accounts = local_response.accounts

          resolve({remote_accounts, my_accounts})
        onError: (error)-> reject('Impossible de récupérer les comptes bancaires')
      })
    )

  update_my_accounts: (local_params)->
    self = this
    promise = new Promise((resolve, reject)->
      self.local_fetch({
        url: '/retriever/create_bank_accounts',
        data: local_params,
        onSuccess: (data)-> resolve(data)
        onError: (error)-> reject(error)
      })
    )

  get_connectors: ()->
    self = this
    connectors_list = []

    get_banks = (resolve, reject)->
      self.remote_fetch({
        type: 'GET'
        url: "/banks?expand=fields"
        collection: 'banks'
        onSuccess: (data)->
          connectors_list = connectors_list.concat(data)
          resolve()
        onError: (error)-> reject(error)
      })

    get_providers = (resolve, reject)->
      self.remote_fetch({
        type: 'GET'
        url: "/providers?expand=fields"
        collection: 'banks'
        onSuccess: (data)->
          connectors_list = connectors_list.concat(data)
          resolve()
        onError: (error)-> reject(error)
      })

    promise = new Promise((resolve, reject)->
      get_banks(
        get_providers(
          ()-> resolve(connectors_list)
          reject
        )
        reject
      )
    )

  create_or_update_connection: (id, remote_params, local_params)->
    self = this
    id_params = if id > 0 then "/#{id}" else ""

    promise = new Promise((resolve, reject)->
      self.encrypt_params(remote_params, ["id_provider", "id_bank"]).then( (remote_params_encrypted)->
        self.double_fetch({
          remote: { url: "/users/me/connections#{id_params}", data: remote_params_encrypted, type: 'POST' }
          local: { url: "/retriever/create", data: local_params }
          onError: (error)-> reject(error)
          onSuccess: (remote_response, local_response)-> resolve({remote_response, local_response})
        })
      )
    )

  update_additionnal_infos: (id, remote_params, local_params)->
    self = this
    promise = new Promise((resolve, reject)->
      if id > 0
        self.encrypt_params(remote_params).then( (remote_params_encrypted)->
          self.double_fetch({
            remote: { url: "/users/me/connections/#{id}", data: remote_params_encrypted, type: 'POST' }
            local: { url: "/retriever/add_infos", data: local_params }
            onError: (error)-> reject(error)
            onSuccess: (response_remote, response_local)-> resolve({response_remote, response_local})
          })
        )
      else
        reject('Erreur de chargement du connecteur')
    )

  delete_connection: (id)->
    self = this
    promise = new Promise((resolve, reject)->
      self.sync_connection('destroy', id).then(resolve, reject)
    )

  trigger_connection: (id)->
    self = this
    promise = new Promise((resolve, reject)->
      self.sync_connection('trigger', id).then(resolve, reject)
    )

  request_new_connector: (remote_params, local_params)->
    self = this
    promise = new Promise((resolve, reject)->
      self.encrypt_params(remote_params, ["api", "name", "url", "types", "comment", "email", "login", "password"]).then( (remote_params_encrypted)->
        self.double_fetch({
          remote: { url: "/connectors", data: remote_params_encrypted, type: 'POST' }
          local: { url: "/account/new_provider_requests", data: local_params }
          onError: (error)-> reject(error)
          onSuccess: (response_remote, response_local)-> resolve({response_remote, response_local})
        })
      )
    )

  sync_connection: (type, id)->
    self = this
    promise = new Promise((resolve, reject)->
      budgea_id = ''
      if type == 'destroy'
        remote_method = 'DELETE'
      else
        remote_method = "PUT"

      local_request = (params)->
          self.local_fetch({
            url: "/retriever/#{type}"
            data: params
            onSuccess: (data)-> resolve(data)
            onError: (error)-> reject(error)
          })

      do_sync = ()->
        if budgea_id != ''
          self.remote_fetch({
            url: "/users/me/connections/#{budgea_id}"
            type: remote_method
            onSuccess: (data)-> local_request({id: id, success: true, data_remote: data})
            onError: (error)-> local_request({id: id, success: false, error_message: error})
          })
        else
          local_request({ id: id, success: true, data_remote: {} })

      self.local_fetch({
        url: "/retriever/get_retriever_infos"
        data: {id: id, remote_method: remote_method}
        onSuccess: (data)->
          budgea_id = data.budgea_id
          self.set_tokens({ bi_token: data.bi_token })
          if data.deleted != undefined && data.deleted == true
            resolve({success: true})
          else
            do_sync()
        onError: (error)-> reject(error)
      })
    )

  local_fetch: (options)->
    method = options.type || 'POST'
    url = options.url || ''
    params = @dataCompact(options.data) || {}
    onSuccess = options.onSuccess || ()->{}
    onError = options.onError || ()->{}

    if @user_token != undefined && @user_token != null
      auth_params = { access_token: @user_token }
      Object.assign(params, params, auth_params)

    $.ajax
      url: "#{@local_host}#{url}"
      data: params
      type: method
      success: (data) ->
        if data.success
          onSuccess(data)
        else
          onError(data.error_message)
      error: (data) -> onError("Service interne non disponible")

  remote_fetch: (options)->
    method = options.type || 'GET'
    url = options.url || ''
    body = @dataCompact(options.data) || {}
    headers = options.headers || {}
    use_secrets = options.use_secrets || false
    onSuccess = options.onSuccess || ()->{}
    onError = options.onError || ()->{}
    collection = options.collection || ''

    xhr = new XMLHttpRequest()
    xhr.open(method, "#{@api_base_url}#{url}")

    xhr.setRequestHeader("Accept", "json")
    xhr.setRequestHeader("Content-Type", "application/json")

    if @bi_token != undefined && @bi_token != null && @bi_token != ''
      xhr.setRequestHeader("Authorization", "Bearer #{@bi_token}")

    xhr.onload = ()->
      if [200, 202, 204, 400, 403, 500, 503].includes(xhr.status)
        try
          response = JSON.parse(xhr.responseText)
          message = response.message || response.description || ''
          if message != ''
            message = "(#{message})"

          switch response.code
            when 'wrongpass' then error_message = "Mot de passe incorrecte. #{message}"
            when 'websiteUnavailable' then error_message = "Site web indisponible. #{message}"
            when 'bug' then error_message = "Service indisponible. #{message}"
            when 'config' then error_message = response.description
            when 'actionNeeded' then error_message = "Veuillez confirmer les nouveaux termes et conditions. #{message}"
            when 'missingParameter' then error_message = "Erreur de paramètre #{message}"
            when 'invalidValue' then error_message = "Erreur de paramètre #{message}"
            when 'keymanager' then error_message = "Erreur de cryptage interne #{message}"
            when 'internalServerError' then error_message = "Erreur du service externe #{message}"
            else error_message = "#{message}"

          success = if error_message.length > 0 then false else true
          data_collect = if collection.length > 0 then response[collection] else response

          if success
            onSuccess(data_collect)
          else
            onError(error_message)
        catch: (e)->
          onError("service non disponible (Error: #{xhr.status})")
      else
        onError("service non disponible (Error: #{xhr.status})")
    xhr.onerror = ()->
      onError("service non disponible (Error: #{xhr.status})")


    auth_params = { client_id: @api_client_id, client_secret: @api_client_secret }
    if use_secrets
      Object.assign(body, body, auth_params)

    body = JSON.stringify(body)
    xhr.send(body)

  double_fetch: (options)->
    url_local = options.local.url
    type_local = options.local.type || 'POST'
    params_local = options.local.data || {}

    url_remote = options.remote.url
    type_remote = options.remote.type || 'GET'
    params_remote = options.remote.data || {}
    collection_remote = options.remote.collection || ''
    use_secrets_remote = options.remote.use_secrets || false

    onError = options.onError || ()->{}
    onSuccess = options.onSuccess || ()->{}

    self = this
    @remote_fetch({
      url: url_remote
      type: type_remote
      data: params_remote
      collection: collection_remote
      use_secrets: use_secrets_remote
      onError: (error)-> onError(error)
      onSuccess: (remote_response)->
        self.local_fetch({
          url: url_local
          type: type_local
          data: { data_local: self.dataCompact(params_local), data_remote: self.dataCompact(remote_response) }
          onError: (error)-> onError(error)
          onSuccess: (local_response)-> onSuccess(remote_response, local_response)
        })
    })

  init_encryptor: ()->
    cryptographer = new Jose.WebCryptographer()
    public_rsa_key = Jose.Utils.importRsaPublicKey(@api_ky, "RSA-OAEP")
    @encryptor = new JoseJWE.Encrypter(cryptographer, public_rsa_key)
    @encryptor.addHeader("kid", @api_ky.kid)

  encrypt_params: (data, _except)->
    self = this
    data = @dataCompact(data)
    promise = new Promise( (resolve)->
      except = _except || []
      keys = Object.keys(data)

      count = keys.length || 0
      if self.encryptor != undefined && self.encryptor != null && count > 0
        for k in keys
          if !except.includes(k)
              self.encrypt(data[k], k).then(
                (encrypted)->
                  _k = encrypted.key
                  _value = encrypted.response
                  data[_k] = _value
                  count--
                  if count <= 0
                    resolve(data)
              )
          else
            count--
            if count <= 0
              resolve(data)
      else
        resolve(data)
    )

  encrypt: (value, key)->
    self = this
    promise = new Promise( (resolve)->
      self.encryptor.encrypt(value).then(
        (result) ->
          resolve({key: key, response: result})
      ).catch((e)->
        resolve({key: key, response: value})
      )
    )

  dataCompact: (params)->
    filtered = params

    if $.isArray(params)
      filtered = params.filter((n)->
        return n != undefined && n != null
      )
    else if $.isPlainObject(params)
      keys = Object.keys(filtered)
      for k in keys
        value = filtered[k]
        if value == undefined || value == null
          delete filtered[k]

    filtered
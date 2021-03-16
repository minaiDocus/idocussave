_require("/assets/jose.js")

class Idocus.BudgeaApi
  constructor: ()->
    @encryptor = null
    @user_profiles = {}
    @local_host = "#{location.protocol}//#{location.host}"
    @request_source = ''
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


    not_registered = ()->
      self.remote_fetch({
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

    if @bi_token.length == 0
      not_registered()
    else
      @remote_fetch({
        url: "/users/me/terms"
        type: "GET"
        onError:(error)-> got_error(error)
        onSuccess: (data)->
          if data.to_sign == true
            not_registered()
          else
            self.init_or_create_user()
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
        self.remote_fetch({
          url: '/users/me/profiles'
          type: 'GET'
          collection: 'profiles'
          onError: (error)-> resolve()
          onSuccess: (remote_data)->
            self.user_profiles = remote_data[0]
            resolve()
        })
    )

  get_accounts_of: (connector_id, full_result) ->
    self = this
    remote_accounts = []
    my_accounts = []
    full_result = full_result || false

    if parseInt(connector_id) > 0
      remote_url = "/users/me/connections/#{connector_id}/accounts?all"
    else
      remote_url = "/users/me/accounts?all"

    promise = new Promise((resolve, reject)->
      self.double_fetch({
        remote: { url: remote_url, type: 'GET', collection: 'accounts' }
        local: { url: '/retriever/get_my_accounts', data: {connector_id: connector_id, full_result: full_result} }
        onSuccess: (remote_response, local_response)->
          ### Respond to remote response ###
          remote_accounts = remote_response

          ### Respond to local response ###
          my_accounts = local_response.accounts

          resolve({remote_accounts, my_accounts})
        onError: (error)-> reject('Impossible de récupérer les comptes bancaires')
      })
    )

  update_my_accounts: (accounts, options)->
    self = this
    promise = new Promise((resolve, reject)->
      # We activate all selected accounts first
      error = false

      for account in accounts
        if(!error)
          self.remote_fetch({
            url: "/users/me/connections/#{account.id_connection}/accounts/#{account.id}?all",
            type: 'POST',
            data: { disabled: 0 },
            collection: 'accounts',
            onError: (data)-> error = true
          })

      if(!error)
        self.local_fetch({
          url: '/retriever/create_bank_accounts',
          data: { accounts: accounts, options: options || {} },
          onSuccess: (data)-> resolve(data)
          onError: (error)-> reject(error)
        })
      else
        reject("Erreur lors de l'activation des comptes bancaires séléctionnés")
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
          setTimeout(resolve, 2000)
        onError: (error)-> reject(error)
      })

    get_providers = (resolve, reject)->
      self.remote_fetch({
        type: 'GET'
        url: "/providers?expand=fields"
        collection: 'banks'
        onSuccess: (data)->
          connectors_list = connectors_list.concat(data)
          setTimeout(resolve, 2000)
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

    id_params       = ""
    @request_source = 'create'

    if id > 0
      id_params = "/#{id}"
      @request_source = 'update'

    promise = new Promise((resolve, reject)->
      self.encrypt_params(remote_params, ["id_provider", "id_bank", "openapiwebsite", "directaccesswebsite"]).then( (remote_params_encrypted)->
        self.double_fetch({
          remote: { url: "/users/me/connections#{id_params}", data: remote_params_encrypted, type: 'POST' }
          local: { url: "/retriever/create", data: local_params }
          onError: (error)->
            self.request_source = ''
            reject(error)
          onSuccess: (remote_response, local_response)->
            self.request_source = ''
            resolve({remote_response, local_response})
        })
      )
    )

  update_additionnal_infos: (id, remote_params, local_params)->
    self = this
    promise = new Promise((resolve, reject)->
      if id > 0
        self.encrypt_params(remote_params, ["openapiwebsite", "directaccesswebsite"]).then( (remote_params_encrypted)->
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

  update_contact: (data)->
    self = this
    promise = new Promise((resolve, reject)->
      self.remote_fetch({
        url: "/users/me/profiles/me"
        data: {contact: data}
        type: "POST"
        onSuccess: (data)-> resolve(data)
        onError: (error)-> reject(error)
      })
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
            success_only: true
            onSuccess: (data)->
              connections = data['collection']
              message     = data['message']
              _success = false

              if message == ''
                _success = true

              if message.match(/Erreur: 404/) && remote_method == 'DELETE'
                _success = true
                connections = {}

              local_request({id: id, success: _success, data_remote: connections})
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

  refresh_connection: (id, data_refresh) ->
    self      = this
    budgea_id = ''

    promise = new Promise((resolve, reject)->
      local_request = (params)->
          self.local_fetch({
            url: "/retriever/update_budgea_error_message"
            type: 'POST'
            data: params
            onSuccess: (data)-> resolve(data)
            onError: (error)-> reject(error)
          })

      do_sync = ()->
        if budgea_id != ''
          self.remote_fetch({
            url: "/users/me/connections/#{budgea_id}"
            type: 'POST'
            data: data_refresh
            success_only: true
            onSuccess: (data)->
              _success = false
              if data['message'] == ''
                _success = true
              local_request({id: id, success: _success, connections: data['collection']})
          })
        else
          local_request({ id: id, success: false, connections: {} })

      self.local_fetch({
        url: "/retriever/get_retriever_infos"
        data: {id: id, remote_method: 'POST'}
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

  webauth: (id, is_new)->
    if ($('#account_id_'+ id ).length > 0)
      user_id                 = $('#account_id_'+ id ).val()
      field_ido_capabilities  = $('#field_ido_capabilities_'+ id)
      ido_connector_id        = $('#ido_connector_id_'+ id )
      field_ido_custom_name   = $('#field_ido_custom_name_'+ id )
      ido_connector_name      = $('#ido_connector_name_'+ id )
    else
      user_id                 = $('#account_id').val()
      field_ido_capabilities  = $('#field_ido_capabilities')
      ido_connector_id        = $('#ido_connector_id')
      field_ido_custom_name   = $('#field_ido_custom_name')
      ido_connector_name      = $('#ido_connector_name')

    state = btoa("{
                    \"user_id\": \"#{user_id}\",
                    \"ido_capabilities\": \"#{field_ido_capabilities.val().replace('"', '\'')}\",
                    \"ido_connector_id\": \"#{ido_connector_id.val().replace('"', '\'')}\",
                    \"ido_custom_name\": \"#{field_ido_custom_name.val().replace('"', '\'')}\",
                    \"ido_connector_name\": \"#{ido_connector_name.val().replace('"', '\'')}\"
                }")

    url = '/retriever/fetch_webauth_url'

    error = (response) ->
      $('#budgea_information_fields .feedparagraph').remove()
      $('#budgea_information_fields .actions').show()
      alert(response.error)

    success = (response) ->
      $('#budgea_information_fields .feedparagraph').remove()
      $('#budgea_information_fields .actions').show()
      domparser = new DOMParser()
      data = domparser.parseFromString(response.html_dom, 'text/html')
      redirect_url = $(data).find('a').attr('href')

      if(redirect_url != undefined && redirect_url != null)
        window.location.href = redirect_url
      else
        error({error: 'Erreur de paramètre'})

    $('#budgea_information_fields .actions').hide()
    $('#budgea_information_fields .actions').after('<p class="feedparagraph">Redirection en cours ... </p>')
    this.local_fetch({url: url, type: 'POST', data: {id: id, user_id: user_id, is_new: is_new, state: state}, onSuccess: success, onError: error})

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
      error: (data) ->
        onError("Service interne non disponible")

  remote_fetch: (options)->
    self = this
    method = options.type || 'GET'
    url = options.url || ''
    body = @dataCompact(options.data) || {}
    headers = options.headers || {}
    use_secrets = options.use_secrets || false
    onSuccess = options.onSuccess || ()->{}
    onError = options.onError || ()->{}
    collection = options.collection || ''
    success_only = options.success_only || false

    xhr = new XMLHttpRequest()
    xhr.open(method, "#{@api_base_url}#{url}")

    xhr.setRequestHeader("Accept", "json")
    xhr.setRequestHeader("Content-Type", "application/json")

    if @bi_token != undefined && @bi_token != null && @bi_token != ''
      xhr.setRequestHeader("Authorization", "Bearer #{@bi_token}")

    parse_error = (status) ->
      message = "Service non disponible (Erreur: #{status})"

      if status == 404
        message = "Connecteur externe innexistant ou supprimé (Erreur: #{status})"
      else if status == 401
        message = "Authorisation requise (Erreur: #{status})"

      if success_only
        onSuccess({ collection: {}, message: message })
      else
        onError(message)

    xhr.onload = ()->
      if [200, 202, 204, 400, 403, 500, 503].includes(xhr.status)
        try
          response = JSON.parse(xhr.responseText)
          message = response.message || response.description || ''
          if message != ''
            message = "(#{message})"

          if self.request_source == 'create' && response.id != 'undefined' && response.id != null && parseInt(response.id) > 0
            console.log('----jump-creation---')
            console.error(response)
            error_message = '' #we consider that there is no error when an id_connection is present only on creation
          else
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

          if success_only
            onSuccess({ collection: data_collect, message: error_message })
          else
            if success
              onSuccess(data_collect)
            else
              onError(error_message)
        catch: (e)->
          parse_error(xhr.status)
      else
        parse_error(xhr.status)

    xhr.onerror = ()->
      parse_error(xhr.status)


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
        # Data encryption is not active for app production budgea now, so we disable data encryption
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
        # resolve(data)
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
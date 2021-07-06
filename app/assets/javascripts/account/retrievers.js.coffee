_require("/assets/budgea_api.js")

Idocus.vent = _.extend({}, Backbone.Events)

Idocus.refreshRetrieversTimer = null

update_warning = ->
  $('.notify-warning').addClass('hide')
  $('.to_disable_later').removeClass('to_disable_later')

  if $('#bank_settings .should_be_disabled_bank_account').length > 0
    $('#bank_settings .should_be_disabled_bank_account').each (e) ->
      self               = $(this)
      should_be_disabled = self.attr('data-disabled')
      if should_be_disabled == '1'
        self.addClass('to_disable_later')

  if $('.to_disable_later').length > 0
    $('.notify-warning').removeClass('hide')

jQuery ->
  Idocus.retriever_contains_name  = ''
  Idocus.retriever_contains_state = ''
  if $('#budgea_sync').length > 0
    router = new Idocus.Routers.BudgeaRetrieversRouter()
    Idocus.budgeaApi = new Idocus.BudgeaApi()
    Idocus.budgeaApi.init_for_user()
    Backbone.history.start()

  if $('#connectors_list').length > 0
    router = new Idocus.Routers.BudgeaConnectorsListRouter()
    Idocus.budgeaApi = new Idocus.BudgeaApi()
    Backbone.history.start()
    $('.export_connector_xls').prop('disabled', true)

  if $('#retrieved_documents.select, #bank_accounts.select').length > 0
    $('#master_checkbox').change ->
      if $(this).is(':checked')
        $('.checkbox').prop('checked', true);
      else
        $('.checkbox').prop('checked', false);

  if $('.retrievers_list').length > 0
    budgeaApi = new Idocus.BudgeaApi()

    refreshRetrievers = (id)->
      if Idocus.refreshRetrieversTimer == null
        load_retrievers_list()
        Idocus.refreshRetrieversTimer = window.setInterval(load_retrievers_list, 10000)
      if id != undefined && id != null
        $('.destroy_retriever_'+id).show()
        $('.trigger_retriever_'+id).show()

    releaseRetrieversTimer = (id)->
      window.clearInterval(Idocus.refreshRetrieversTimer)
      Idocus.refreshRetrieversTimer = null
      if id != undefined && id != null
        $('.destroy_retriever_'+id).hide()
        $('.trigger_retriever_'+id).hide()

    load_retrievers_list = (url) ->
      _url = ''           
      if url != undefined
        _url = url        
      else
        direction = $('#direction').val() || 'desc'
        sort      = $('#sort').val()      || 'created_at'
        per_page  = $('#per_page').val()  || 20
        page      = $('#page').val()      || 1
        
        _url = 'retrievers?part=true'
        if direction != ''
          _url += '&direction=' + direction
        if sort != ''
          _url += '&sort=' + sort
        if per_page != ''
          _url += '&per_page=' + per_page          
        if page != ''
          _url += '&page=' + page        
        if Idocus.retriever_contains_name != ''
          _url += '&retriever_contains[name]=' + Idocus.retriever_contains_name
        if Idocus.retriever_contains_state != ''
          _url += '&retriever_contains[state]=' + Idocus.retriever_contains_state
        
      
      $.ajax
        url: _url        
        dataType: 'html'
        type: 'GET'
        success: (data) ->
          $('.popover').remove()
          $('.tooltip').remove()
          $('thead a, .list_options a').unbind 'click'
          $('.destroy_retriever').unbind 'click'
          $('.trigger_retriever').unbind 'click'
          $('.scarequire_decoupled_button').unbind 'click'
          if $('.retrievers_list').html() != data
            $('.retrievers_list').html(data)
          $('[rel=popover]').popover()
          $('[rel=tooltip]').tooltip()



          $('.list_options a').bind 'click', (e) ->
            e.preventDefault()
            url = $(this).attr('href')
            $('#per_page').val($(this).text())
            load_retrievers_list()          

          $('thead a').bind 'click', (e) ->
            e.preventDefault()
            url = $(this).attr('href')
            direction_sort = url.split('?')[1]
            tmp_direction  = direction_sort.split('&')[0]
            tmp_sort       = direction_sort.split('&')[1]           
            $('#direction').val(tmp_direction.split('=')[1])
            $('#sort').val(tmp_sort.split('=')[1])
            load_retrievers_list()

          $('.destroy_retriever').bind 'click', (e)->
            e.preventDefault()
            self = $(this)

            fClose = () ->
              $('#delConfirm.modal .loading').addClass('hide')
              $('#delConfirm.modal .buttonsAction').removeClass('hide')
              $('#delConfirm.modal').modal('hide')

            onConfirm = () ->
              id = self.attr('data-id')
              releaseRetrieversTimer(id)
              $('#delConfirm.modal .loading').removeClass('hide')
              $('#delConfirm.modal .buttonsAction').addClass('hide')
              $('.state_field_'+id).html('<span class="badge fs-origin badge-secondary">Suppression en cours</span>')
              budgeaApi.delete_connection(id).then(
                ()->
                  fClose()
                  refreshRetrievers(id)
                ()->
                  fClose()
                  refreshRetrievers(id)
                  $('.state_field_'+id).html('<span class="badge fs-origin badge-danger">Erreur de suppression</span>')
              )

            $('#delConfirm.modal').modal('show')
            $("#delConfirm.modal #del_confirm_button").unbind().one('click', onConfirm)
            $("#delConfirm.modal #del_cancel_button").unbind().one("click", fClose)

          fClose = () ->
            $('#syncConfirm.modal .loading').addClass('hide')
            $('#syncConfirm.modal .buttonsAction').removeClass('hide')
            $('#syncConfirm.modal').modal('hide')

          fShow = () ->
            $('#syncConfirm.modal').modal('show')
            $("#syncConfirm.modal #sync_cancel_button").unbind().one("click", fClose)

          $('.trigger_retriever').bind 'click', (e)->
            e.preventDefault()
            self = $(this)

            onConfirm = () ->
              id = self.attr('data-id')
              releaseRetrieversTimer(id)
              $('#syncConfirm.modal .loading').removeClass('hide')
              $('#syncConfirm.modal .buttonsAction').addClass('hide')
              $('.state_field_'+id).html('<span class="badge fs-origin badge-secondary">Synchronisation en cours</span>')
              budgeaApi.trigger_connection(id).then(
                ()->
                  fClose()
                  refreshRetrievers(id)
                ()->
                  fClose()
                  refreshRetrievers(id)
                  $('.state_field_'+id).html('<span class="badge fs-origin badge-danger">Erreur de synchronisation</span>')
              )

            # $('#syncConfirm.modal').modal('show')
            # $("#syncConfirm.modal #sync_cancel_button").unbind().one("click", fClose)

            fShow()
            $("#syncConfirm.modal #sync_confirm_button").unbind().one('click', onConfirm)

          $('.scarequire_decoupled_button').on 'click', (e) ->
            e.preventDefault()
            self = $(this)

            onConfirm = () ->
              id = self.attr('data-id')
              releaseRetrieversTimer(id)
              $('#syncConfirm.modal .loading').removeClass('hide')
              $('#syncConfirm.modal .buttonsAction').addClass('hide')
              $('.state_field_'+id).html("<span class='badge fs-origin badge-secondary'>Procedure d'authentification en cours</span>")

              data = ''
              if self.attr('id') == 'decoupled'
                data = { resume: true }

              budgeaApi.refresh_connection(id, data).then(
                ()->
                  fClose()
                  refreshRetrievers(id)
                ()->
                  fClose()
                  refreshRetrievers(id)
                  $('.state_field_'+id).html('<span class="badge fs-origin badge-danger">Erreur d\'authentification</span>')
              )

            fShow()
            $("#syncConfirm.modal #sync_confirm_button").unbind().one('click', onConfirm)

          $('.webauth_button').on 'click', (e) ->
            e.preventDefault()
            self = $(this)

            if confirm("Voulez-vous vraiement lancer la procédure d'authentification ?")
              id = self.attr('data-id')
              releaseRetrieversTimer(id)
              $('#loading_'+id).removeClass('hide')
              self.attr("disabled", true)

              id_connection = $('#ido_connector_id_'+ id).val() || 0
              if id_connection != 0
                budgeaApi.webauth(id_connection, false)

    releaseRetrieversTimer()    
    window.retrievers_url = 'retrievers?part=true'
    refreshRetrievers()

    $('.reset_filter').on 'click', (e) ->
      e.preventDefault()
      $('#retriever_contains_name').val('')
      $('#retriever_contains_state').val('')
      $('#direction').val(null)
      $('#sort').val(null)
      $('#per_page').val(null)
      $('#page').val(null)
      Idocus.retriever_contains_name = ''
      Idocus.retriever_contains_state = ''
      load_retrievers_list()

  if $('#new_provider_requests_list').length > 0
    $('.show_provider_request').on 'click', (e)->
      e.preventDefault()
      showDetails = $('#showProviderRequest')
      id = $(this).attr('data-id')
      detail = $('#new_provider_requests_list .detail_'+id)

      showDetails.find('.created_at').html(detail.find('.created_at').html())
      showDetails.find('._state').html(detail.find('._state').html())
      showDetails.find('.name').html(detail.find('.name').html())
      showDetails.find('.url').html(detail.find('.url').html())
      showDetails.find('.email').html(detail.find('.email').html())
      showDetails.find('.login').html(detail.find('.login').html())
      showDetails.find('.types').html(detail.find('.types').html())
      showDetails.find('.description').html(detail.find('.description').html() || 'Aucune')

      showDetails.modal()

  if $('#form_new_provider_request').length > 0
    budgeaApi = new Idocus.BudgeaApi()
    common = new Idocus.Models.Common()
    $('#new_new_provider_request').on 'submit', (e)->
      e.preventDefault()
      form = $(this)
      form.find('.form-actions .actions').css(display: 'none')
      form.find('.form-actions .actions').after('<div class="feedback active" style="margin: auto"></div>')
      $('#form_new_provider_request #information').addClass('hide')

      form_data = common.serialize_form_json(form)

      login_param = form_data['new_provider_request[login]'] || form_data['new_provider_request[email]']
      remote_params = {
                        api:      budgeaApi.api_base_url.split('/')[2],
                        name:     form_data['new_provider_request[name]'],
                        url:      form_data['new_provider_request[url]'],
                        email:    form_data['new_provider_request[email]'],
                        login:    login_param,
                        password: form_data['new_provider_request[password]'],
                        types:    form_data['new_provider_request[types]'],
                        comment:  form_data['new_provider_request[description]']
                      }

      local_params =  {
                        authenticity_token: form_data['authenticity_token'],
                        name:               form_data['new_provider_request[name]'],
                        url:                form_data['new_provider_request[url]'],
                        email:              form_data['new_provider_request[email]'],
                        login:              form_data['new_provider_request[login]'],
                        types:              form_data['new_provider_request[types]'],
                        description:        form_data['new_provider_request[description]']
                      }

      valid_fields = (el)->
        valid = true
        el.find('.hint_error').remove()
        el.find('.required').removeClass('error')
        el.find(':input.required').each((index)->
          if $(this).val() == '' || $(this).val() == undefined
            valid = false
            $(this).after('<span class="help-inline hint_error">champ obligatoire</span>')
            $(this).parent().parent('.required').addClass('error')
        )
        if login_param == '' || login_param == undefined
          valid = false
          el.find('#new_provider_request_email, #new_provider_request_login').each((i)->
            $(this).after('<span class="help-inline hint_error">Email ou Identifiant obligatoire</span>')
            $(this).parent().parent().addClass('error')
            $(this).parent().parent().addClass('required')
          )
        valid

      if valid_fields(form)
        budgeaApi.request_new_connector(remote_params, local_params).then(
          (data)->
            location.href = "/account/new_provider_requests/new?create=1"
          (error)->
            form.find('.form-actions .actions').css(display: 'block')
            form.find('.form-actions .feedback').remove()
            $(document).scrollTop(0)
            $('#form_new_provider_request #information').html("<span>#{error}</span>")
            $('#form_new_provider_request #information').removeClass('hide')
        )
      else
        form.find('.form-actions .actions').css(display: 'block')
        form.find('.form-actions .feedback').remove()

  if $('#bank_accounts.select').length > 0
    Idocus.budgeaApi = new Idocus.BudgeaApi()
    Idocus.budgeaApi.init_for_user()

    t_body = $('#bank_accounts.select tbody#all_accounts_list')
    connector_id = $('#bank_accounts.select #bank_account_contains_retriever_budgea_id').val()

    accounts_lists = []

    parseAccounts = (data) ->
      html = ''
      local_accounts = data.my_accounts
      accounts_lists = data.remote_accounts

      for account in accounts_lists
        bank = local_accounts.find((a)->
          return parseInt(a.api_id) == parseInt(account.id)
        ) || {}

        checked = ''
        if(bank['is_used'] != undefined && bank['is_used'])
          checked = 'checked="checked"'

        bank_name = $('#bank_accounts.select #bank_account_contains_retriever_budgea_id option[value="'+account.id_connection+'"]').html()

        html += '<tr>'
        html += '<td><input type="checkbox" class="checkbox" name="bank_account_ids[]" value="'+account.id+'" '+checked+' /></td>'
        html += '<td>'+(bank_name || "-")+'</td>'
        html += '<td>'+account.name+'</td>'
        html += '<td>'+account.number+'</td>'
        html += '</tr>'
 
      t_body.html(html)

    Idocus.budgeaApi.get_accounts_of(connector_id, true).then(
      (data)-> parseAccounts(data)
      (error)-> t_body.html('<tr><td colspan="4">Erreur de chargement des comptes bancaires</td></tr>')
    )

    $('#bank_accounts.select .btn-selection').on 'click',  (e)->
      e.preventDefault()
      if confirm('Etes vous sûr?')
        $('.form-actions').html('<div class="feedback active"></div>')

        data = $('#bank_accounts.select .form-selection').serializeArray()

        selected_ids = []
        for dt in data
          if /bank_account_ids/i.test(dt.name)
            selected_ids.push(parseInt(dt.value))

        accounts = accounts_lists.filter((a)->
          return selected_ids.includes(parseInt(a.id))
        )

        Idocus.budgeaApi.update_my_accounts(accounts, {force_disable: true}).then(
          ()->
            window.location.href = "#{Idocus.budgeaApi.local_host}/account/bank_accounts"
            $('#all_accounts_list').html('<span class="text-info">Modifié avec succès.</span>')
          (error)->
            $('.form-actions').html('<span>Impossible de modifier la séléction</span>')
        )

  $('select#account_id').chosen({
    search_contains: true,
    no_results_text: 'Aucun résultat correspondant à'
  })

  $('select#account_id').on 'change', (e)->
    $('#retrievers #account_id_form').submit()

  $('#retrievers a.disable').on 'click', (e)->
    $('#retrievers .hint_selection').remove()
    text = $(this).attr('title')
    $('#retrievers #account_id_form').after("<span class='hint_selection alert alert-danger margin1left'>#{text}</span>")
    $('#retrievers .hint_selection').delay(2500).fadeOut('fast')

  $(".retriever_search").on 'submit', (e) ->
    return false

  $('.retriever_filter').on 'click', (e) ->    
    Idocus.retriever_contains_name  = $('#retriever_contains_name').val()
    Idocus.retriever_contains_state = $('#retriever_contains_state').val() 
    load_retrievers_list()


  if $('#bank_settings #create_bank_account.modal').length > 0
    $('#submit_bank_account').attr('disabled', true)

    currencies = {
      usd: "Dollar",
      cad: "Dollar Australien",
      chf: "Franc",
      jpy: "Yen",
      nzd: "Dollar Néo-Zélandais",
      eur: "Euro",
      gbp: "Livre",
      sek: "Couronne Suédoise",
      dkk: "Couronne Danoise",
      nok: "Couronne Norvégienne",
      sgd: "Dollar de Singapour",
      czk: "Couronne Tchèque",
      hkd: "Dollar de Hong Kong",
      mxn: "Peso Mexicain",
      pln: "Zloty",
      rub: "Rouble",
      try: "Livre turque",
      zar: "Rand",
      cnh: "Yuan",
    }

    connectors_list  = new Idocus.Collections.Connectors()
    Idocus.budgeaApi = new Idocus.BudgeaApi()
    $('select#bank_account_bank_name').empty().append("<option value=''>Chargement en cours ... Veuillez patientez svp.</option>");

    connectors_list.fetch_all().then(
      ()->
        distinct = (value, index, self) ->
          return self.findIndex((e)->value['id'] == e['id']) == index

        options = $('select#bank_account_bank_name').empty()
        banks = connectors_list.connectors_fetched.filter(distinct)

        # ADD BANKS HERE
        banks.push({ name: 'UBS', capabilities: ['bank'] })
        # ADD BANKS HERE - END

        banks = banks.sort((a,b)->
          if a['name'].toLowerCase() < b['name'].toLowerCase()
            return -1;
          if a['name'].toLowerCase() > b['name'].toLowerCase()
            return 1;
          return 0;
        )

        $.each banks, (index, element) ->
          if $.inArray('bank', element['capabilities']) > -1
            bank_name = element['name']
            options.append("<option value=\"#{bank_name}\">#{bank_name}</option>")
        $('#submit_bank_account').attr('disabled', false)
      (error)->
        if $('form#new_bank_account').length > 0
          $('select#bank_account_bank_name').empty().append("<option value=''>Erreur de chargement de la page, Veuillez la réactualiser !</option>")
          $("select#bank_account_bank_name").css({backgroundColor: "#ff9966", color: 'black'})
    )

    if $('form#new_bank_account').length > 0
      $("select#bank_account_original_currency_symbol").on 'change', (e)->
        selected = $("select#bank_account_original_currency_symbol option:selected").text()
        $("#bank_account_original_currency_id").val(selected)
        $("#bank_account_original_currency_name").val(currencies[selected.toLowerCase()])

      $('#submit_bank_account').click (e) ->
        $("#bank_account_name").val($("#bank_account_bank_name").val())
        $('form#new_bank_account').submit()

      $('label.required abbr[title="champ requis"]').css({fontWeight:800, color: 'red'})

  if $('#bank_settings.select .destroy_bank_account, #bank_settings.select .reopen_bank_account').length > 0
    $('.destroy_bank_account, .reopen_bank_account').click (e) ->
      e.preventDefault()
      self = $(this)
      id   = self.data('id')
      number = self.data('number')

      if $(this).hasClass('reopen_bank_account')
        disabled        = false
        disabled_value = 0
        message    = 'est maintenant activé'
        action_name = 'réactiver'
      else
        disabled        = true
        disabled_value = 1
        message         = 'devrait être désactivé dans le mois prochain'
        action_name = 'désactiver'

      if confirm("Vous êtes sur le point de #{action_name} le compte bancaire avec le numéro : #{number}. Etes-vous sûr ?")
        $.ajax(
          type: 'POST',
          data: JSON.stringify({ id: id, disabled: disabled, message: message })
          url: '/account/bank_settings/should_be_disabled',
          contentType: 'application/json',
          ).success (response) ->
            alert_element = ''

            if response['success'] == true
              alert_element = '<div class="alert alert-success col-sm-12"><a class="close" data-dismiss="alert">×</a><div id="flash_alert-success">' + response['message'] + '</div></div>'
            else
              alert_element = '<div class="alert alert-danger col-sm-12"><a class="close" data-dismiss="alert">×</a><div id="flash_alert-danger">' + response['message'] + '</div></div>'

            $('.alerts').html('<div class="row-fluid">' + alert_element + '</div>')
            self.closest('tr').attr('data-disabled', "#{disabled_value}")
            $('[rel="tooltip"]').tooltip("hide")

            if disabled_value == 0
              $(".destroy_bank_account_#{id}").removeClass('hide')
              $(".edit_bank_account_#{id}").removeClass('hide')
              $(".reopen_bank_account_#{id}").addClass('hide')
            else if disabled_value == 1
              $(".reopen_bank_account_#{id}").removeClass('hide')
              $(".destroy_bank_account_#{id}").addClass('hide')
              $(".edit_bank_account_#{id}").addClass('hide')

            update_warning()

  update_warning()

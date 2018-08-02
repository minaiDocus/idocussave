_require("/assets/budgea_api.js")

Idocus.vent = _.extend({}, Backbone.Events)

Idocus.refreshRetrieversTimer = null

jQuery ->
  if $('#budgea_sync').length > 0
    router = new Idocus.Routers.BudgeaRetrieversRouter()
    Idocus.budgeaApi = new Idocus.BudgeaApi()
    Idocus.budgeaApi.init_for_user()
    Backbone.history.start()

  if $('#connectors_list').length > 0
    router = new Idocus.Routers.BudgeaConnectorsListRouter()
    Idocus.budgeaApi = new Idocus.BudgeaApi()
    Backbone.history.start()

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
        direction = $('#direction').val() || ''
        sort      = $('#sort').val()      || ''
        per_page  = $('#per_page').val()  || ''
        page      = $('#page').val()      || ''
        _url = 'retrievers?part=true'
        if direction != ''
          _url += '&direction=' + direction
        if sort != ''
          _url += '&sort=' + sort
        if per_page != ''
          _url += '&per_page=' + per_page
        if page != ''
          _url += '&page=' + page
        if window.retriever_contains_name != ''
          _url += '&retriever_contains[name]=' + window.retriever_contains_name
        if window.retriever_contains_state != ''
          _url += '&retriever_contains[state]=' + window.retriever_contains_state
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
          if $('.retrievers_list').html() != data
            $('.retrievers_list').html(data)
          $('[rel=popover]').popover()
          $('[rel=tooltip]').tooltip()

          $('thead a, .list_options a').bind 'click', (e) ->
            e.preventDefault()
            url = $(this).attr('href')
            load_retrievers_list(url)

          $('.destroy_retriever').bind 'click', (e)->
            e.preventDefault()
            if confirm('Voulez-vous vraiment supprimer cette automate?')
              id = $(this).attr('data-id')
              releaseRetrieversTimer(id)
              $('.state_field_'+id).html('<span class="label">Suppression en cours</span>')
              budgeaApi.delete_connection(id).then(
                ()->
                  refreshRetrievers(id)
                ()->
                  refreshRetrievers(id)
                  $('.state_field_'+id).html('<span class="label label-important">Erreur de suppression</span>')
              )

          $('.trigger_retriever').bind 'click', (e)->
            e.preventDefault()
            if confirm('Voulez-vous vraiment synchroniser cette automate?')
              id = $(this).attr('data-id')
              releaseRetrieversTimer(id)
              $('.state_field_'+id).html('<span class="label">Synchronisation en cours</span>')
              budgeaApi.trigger_connection(id).then(
                ()->
                  refreshRetrievers(id)
                ()->
                  refreshRetrievers(id)
                  $('.state_field_'+id).html('<span class="label label-important">Erreur de synchronisation</span>')
              )

    releaseRetrieversTimer()
    window.retriever_contains_name = ''
    window.retriever_contains_state = ''
    window.retrievers_url = 'retrievers?part=true'
    refreshRetrievers()

    $('.retriever_search.form').on 'submit', (e) ->
      window.retriever_contains_name = $('#retriever_contains_name').val()
      window.retriever_contains_state = $('#retriever_contains_state').val()
      e.preventDefault()
      load_retrievers_list()

    $('.reset_filter').on 'click', (e) ->
      e.preventDefault()
      $('#retriever_contains_name').val('')
      $('#retriever_contains_state').val('')
      $('#direction').val(null)
      $('#sort').val(null)
      $('#per_page').val(null)
      $('#page').val(null)
      window.retriever_contains_name = ''
      window.retriever_contains_state = ''
      load_retrievers_list()

  if $('#retrievers .filter, #retrieved_banking_operations .filter, #retrieved_documents .filter').length > 0
    $('a.toggle_filter').click (e) ->
      e.preventDefault()
      if $('.filter').hasClass('hide')
        $('.filter').removeClass('hide')
        $(this).text('Cacher le filtre')
      else
        $('.filter').addClass('hide')
        $(this).text('Afficher le filtre')

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

  $('select#account_id').chosen({
    search_contains: true,
    no_results_text: 'Aucun résultat correspondant à'
  })

  $('select#account_id').on 'change', (e)->
    $('#retrievers #account_id_form').submit()

  $('#retrievers a.disabled').on 'click', (e)->
    $('#retrievers .hint_selection').remove()
    text = $(this).attr('title')
    $('#retrievers #account_id_form #account_id_chosen').after("<span class='hint_selection alert alert-danger margin1left'>#{text}</span>")
    $('#retrievers .hint_selection').delay(2500).fadeOut('fast')

same_id = (element) ->
  element['id'] == window.retriever_id

update_form = ->
  change_providers_list()
  update_provider()

  $('#params').html('')
  $help_block = $('#retriever_type').next('p')
  if $help_block != undefined
    $help_block.remove()

  if $('#retriever_type').val() == 'provider'
    window.retriever_id = parseInt($('#retriever_provider_id').val())
  else
    window.retriever_id = parseInt($('#retriever_bank_id').val())

  if Number.isInteger window.retriever_id
    if $('#retriever_type').val() == 'provider'
      retriever = window.providers.filter(same_id)[0]
    else
      retriever = window.banks.filter(same_id)[0]

    if retriever['capabilities'].length == 2
      $('#retriever_journal_id').parents('.controls').parents('.control-group').show()
      if $('#retriever_type').val() == 'provider'
        $('#retriever_type').after('<p class="help-block red">Récupère les opérations bancaires aussi.</p>')
      else
        $('#retriever_type').after('<p class="help-block red">Récupère les documents aussi.</p>')

    if retriever['id'] == $('#params').data('connector-id')
      attributes = $('#params').data('attributes')
    else
      attributes = {}

    for i in [1..(retriever['fields'].length)]
      field = retriever['fields'][i-1]
      field['param_name'] = 'param' + i
      tmpl_name = 'tmpl-input'
      attribute = attributes[field['param_name']]
      if attribute
        field['value'] = attribute['value']
        field['error'] = attribute['error']
      if field['type'] == 'list'
        tmpl_name = 'tmpl-select'
      if field['type'] == 'date' || field['type'] == 'redirect_uri'
        field['type'] = 'text'
      $('#params').append(tmpl(tmpl_name, field))

change_providers_list = ->
  if $('#retriever_type').val() == 'provider'
    $('#retriever_provider_id').parents('.controls').parents('.control-group').show()
    $('#retriever_bank_id').parents('.controls').parents('.control-group').hide()
    $('#retriever_journal_id').parents('.controls').parents('.control-group').show()
    $('#retriever_bank_id').tokenInput('remove', { id: parseInt($('#retriever_bank_id').val()) })
  else
    $('#retriever_provider_id').parents('.controls').parents('.control-group').hide()
    $('#retriever_bank_id').parents('.controls').parents('.control-group').show()
    $('#retriever_journal_id').parents('.controls').parents('.control-group').hide()
    $('#retriever_provider_id').tokenInput('remove', { id: parseInt($('#retriever_provider_id').val()) })

update_provider = ->
  unless $('#retriever_provider_id').is(':disabled') && $('#retriever_bank_id').is(':disabled')
    result = null
    result = $('#retriever_'+$('#retriever_type').val()+'_id').tokenInput('get')[0]
    if result
      $('#retriever_service_name').val(result.name)
      $('#retriever_name').val(result.name)
    else
      $('#retriever_service_name').val('')
      $('#retriever_name').val('')

jQuery ->
  if $('.retriever_form').length > 0
    window.providers          = $('#providers').data('providers')
    window.selected_providers = $('#providers').data('selectedProviders')
    window.banks              = $('#banks').data('banks')
    window.selected_banks     = $('#banks').data('selectedBanks')

    $('#retriever_type').on 'change', ->
      update_form()

    if $('#retriever_provider_id').is(':disabled')
      $('#retriever_provider_id').addClass('hide')
      $('#retriever_provider_id').after('<input class="string required disabled" disabled="disabled" id="retriever_provider_name" name="retriever[provider_name]" value="'+$('#retriever_service_name').val()+'" type="text">')
    else
      $('#retriever_provider_id').tokenInput window.providers,
        theme: 'facebook'
        searchDelay: 500
        minChars: 1
        resultsLimit: 10
        tokenLimit: 1
        preventDuplicates: true
        prePopulate: window.selected_providers
        hintText: 'Tapez un fournisseur à rechercher'
        noResultsText: 'Aucun résultat'
        searchingText: 'Recherche en cours...'
        onAdd: (item) ->
          update_form()
        onDelete: (item) ->
          update_form()

    if $('#retriever_bank_id').is(':disabled')
      $('#retriever_bank_id').addClass('hide')
      $('#retriever_bank_id').after('<input class="string required disabled" disabled="disabled" id="retriever_bank_name" name="retriever[bank_name]" value="'+$('#retriever_service_name').val()+'" type="text">')
    else
      $('#retriever_bank_id').tokenInput window.banks,
        theme: 'facebook'
        searchDelay: 500
        minChars: 1
        resultsLimit: 10
        tokenLimit: 1
        preventDuplicates: true
        prePopulate: window.selected_banks
        hintText: 'Tapez une banque à rechercher'
        noResultsText: 'Aucun résultat'
        searchingText: 'Recherche en cours...'
        onAdd: (item) ->
          update_form()
        onDelete: (item) ->
          update_form()

    update_form()

  if $('#retrieved_documents.select, #bank_accounts.select').length > 0
    $('#master_checkbox').change ->
      if $(this).is(':checked')
        $('.checkbox').attr('checked', true);
      else
        $('.checkbox').attr('checked', false);

  if $('.retrievers_list').length > 0
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
      $.ajax
        url: _url
        dataType: 'html'
        type: 'GET'
        success: (data) ->
          $('.popover').remove()
          $('.tooltip').remove()
          $('thead a, .list_options a').unbind 'click'
          if $('.retrievers_list').html() != data
            $('.retrievers_list').html(data)
          $('[rel=popover]').popover()
          $('[rel=tooltip]').tooltip()
          $('thead a, .list_options a').bind 'click', (e) ->
            e.preventDefault()
            url = $(this).attr('href')
            load_retrievers_list(url)

    window.retriever_contains_name = ''
    window.retrievers_url = 'retrievers?part=true'
    load_retrievers_list()

    $('.retriever_seach.form').on 'submit', (e) ->
      window.retriever_contains_name = $('#retriever_contains_name').val()
      e.preventDefault()
      load_retrievers_list()
    $('.reset_filter').on 'click', (e) ->
      e.preventDefault()
      $('#retriever_contains_name').val('')
      $('#direction').val(null)
      $('#sort').val(null)
      $('#per_page').val(null)
      $('#page').val(null)
      window.retriever_contains_name = ''
      load_retrievers_list()

    window.setInterval(load_retrievers_list, 5000)

  if $('#retrievers .filter, #retriever_transactions .filter, #retrieved_banking_operations .filter, #retrieved_documents .filter').length > 0
    $('a.toggle_filter').click (e) ->
      e.preventDefault();
      if $('.filter').hasClass('hide')
        $('.filter').removeClass('hide')
        $(this).text('Cacher le filtre')
      else
        $('.filter').addClass('hide')
        $(this).text('Afficher le filtre')

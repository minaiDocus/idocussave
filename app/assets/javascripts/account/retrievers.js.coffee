same_id = (element) ->
  element['id'] == window.retriever_id

update_form = ->
  connector = null
  window.retriever_id = parseInt($('#retriever_connector_id').val())
  if Number.isInteger window.retriever_id
    connector = window.connectors.filter(same_id)[0]

  update_connector_info(connector)
  show_or_hide_journals()

  $('#params').html('')

  if connector
    if connector['id'] == $('#params').data('connector-id')
      attributes = $('#params').data('attributes')
    else
      attributes = {}

    for i in [1..(connector['fields'].length)]
      field = connector['fields'][i-1]
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

show_or_hide_journals = ->
  if $('#retriever_type').val() == 'provider' || $('#retriever_type').val() == 'both'
    $('#retriever_journal_id').removeAttr('disabled')
    $('#retriever_journal_id').parents('.controls').parents('.control-group').show()
  else
    $('#retriever_journal_id').attr('disabled', 'disabled')
    $('#retriever_journal_id').parents('.controls').parents('.control-group').hide()

update_connector_info = (connector) ->
  if connector
    if connector['capabilities'].length == 1 && connector['capabilities'][0] == 'bank'
      $('#retriever_type').val('bank')
      $('#retriever_type_name').val('Opérations bancaires')
    else if connector['capabilities'].length == 1 && connector['capabilities'][0] == 'document'
      $('#retriever_type').val('provider')
      $('#retriever_type_name').val('Documents (Factures)')
    else
      $('#retriever_type').val('both')
      $('#retriever_type_name').val('Documents & Opérations bancaires')
    $('#retriever_service_name').val(connector['name'])
    $('#retriever_name').val(connector['name'])
  else
    $('#retriever_type').val('')
    $('#retriever_type_name').val('')
    $('#retriever_service_name').val('')
    $('#retriever_name').val('')

jQuery ->
  if $('.retriever_form').length > 0
    window.connectors          = $('#connectors').data('connectors')
    window.selected_connectors = $('#connectors').data('selectedConnectors')

    $('#retriever_type').hide()
    $('#retriever_type').after('<input class="string disabled" disabled="disabled" id="retriever_type_name" name="retriever[type_name]" type="text">')

    if $('#retriever_connector_id').is(':disabled')
      $('#retriever_connector_id').addClass('hide')
      $('#retriever_connector_id').after('<input class="string required disabled" disabled="disabled" id="retriever_provider_name" name="retriever[provider_name]" value="'+$('#retriever_service_name').val()+'" type="text">')
    else
      $('#retriever_connector_id').tokenInput window.connectors,
        theme: 'facebook'
        searchDelay: 500
        minChars: 1
        resultsLimit: 10
        tokenLimit: 1
        preventDuplicates: true
        prePopulate: window.selected_connectors
        hintText: 'Tapez un fournisseur/banque à rechercher'
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

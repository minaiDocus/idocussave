same_id = (element) ->
  element['id'] == window.retriever_id

update_form = ->
  if $('#retriever_type').val() == 'provider'
    window.retriever_id = parseInt($('#retriever_provider_id').val())
  else
    window.retriever_id = parseInt($('#retriever_bank_id').val())

  $('.dyn_attr').hide()
  $('.dyn_list_attr').hide()
  $('.dyn_pass_attr').hide()

  $('#retriever_dyn_attr').val('')
  $("label[for='retriever_dyn_list_attr']").html('')
  $('#retriever_dyn_list_attr').html('')
  $("label[for='retriever_dyn_pass_attr']").html('')
  $('#retriever_dyn_pass_attr').val('')

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

    for field in retriever['fields']
      label = '<abbr title="champ requis">*</abbr> ' + field['label']
      if field['name'] == 'login'
        $("label[for='retriever_login']").html(label)
      else if field['name'] == 'password'
        $("label[for='retriever_password']").html(label)
      else if field['type'] == 'list'
        content = ''
        for option in field['values']
          content += '<option value="' + option['value'] + '">' + option['label'] + '</option>'
        $("label[for='retriever_dyn_list_attr']").html(label)
        $('#retriever_dyn_list_attr').html(content)
        if window.selected_dyn_attr_value != null
          $('#retriever_dyn_list_attr option[value="'+(window.selected_dyn_attr_value)+'"]').prop('selected', true)
        $('.dyn_list_attr').show()
        $('#retriever_dyn_attr').val($('#retriever_dyn_list_attr').val())
      else if field['type'] == 'text' || field['type'] == 'date'
        $("label[for='retriever_dyn_attr']").html(label)
        $('.dyn_attr').show()
      else if field['type'] == 'password'
        $("label[for='retriever_dyn_pass_attr']").html(label)
        $('.dyn_pass_attr').show()
  else
    content = '<abbr title="champ requis">*</abbr> Identifiant'
    $("label[for='retriever_login']").html(content)

    content = '<abbr title="champ requis">*</abbr> Mot de passe'
    $("label[for='retriever_password']").html(content)

update_selects_list = ->
  if $('#retriever_type').val() == 'provider'
    $('#retriever_provider_id').parents('.controls').parents('.control-group').show()
    $('#retriever_bank_id').parents('.controls').parents('.control-group').hide()
    $('#retriever_journal_id').parents('.controls').parents('.control-group').show()
  else
    $('#retriever_provider_id').parents('.controls').parents('.control-group').hide()
    $('#retriever_bank_id').parents('.controls').parents('.control-group').show()
    $('#retriever_journal_id').parents('.controls').parents('.control-group').hide()

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

update_all = ->
  $help_block = $('#retriever_type').next('p')
  if $help_block != undefined
    $help_block.remove()
  update_selects_list()
  update_form()
  update_provider()

jQuery ->
  if $('.retriever_form').length > 0
    window.providers = $('#providers').data('providers')
    window.selected_providers = $('#providers').data('selectedProviders')
    window.banks = $('#banks').data('banks')
    window.selected_banks = $('#banks').data('selectedBanks')
    if $('#selected').length > 0
      window.selected_dyn_attr_value = $('#selected').data('dynAttrValue')
    else
      window.selected_dyn_attr_value = null
    update_selects_list()

    $('#retriever_type').on 'change', ->
      update_all()

    update_form()

    $('#retriever_dyn_list_attr').on 'change', ->
      $('#retriever_dyn_attr').val($('#retriever_dyn_list_attr').val())
    $('#retriever_dyn_pass_attr').on 'change', ->
      $('#retriever_dyn_attr').val($('#retriever_dyn_pass_attr').val())

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
          update_all()
        onDelete: (item) ->
          update_all()

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
          update_all()
        onDelete: (item) ->
          update_all()

    update_provider()

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

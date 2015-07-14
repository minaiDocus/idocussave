same_id = (element) ->
  element['id'] == window.fiduceo_retriever_id

update_form = ->
  if $('#fiduceo_retriever_type').val() == 'provider'
    window.fiduceo_retriever_id = $('#fiduceo_retriever_provider_id').val()
  else
    window.fiduceo_retriever_id = $('#fiduceo_retriever_bank_id').val()

  $('#fiduceo_retriever_param1').val('')
  $('#fiduceo_retriever_param2').val('')
  $('#fiduceo_retriever_param3').val('')
  $("label[for='fiduceo_retriever_sparam1']").html('')
  $('#fiduceo_retriever_sparam1').html('')
  $("label[for='fiduceo_retriever_sparam2']").html('')
  $('#fiduceo_retriever_sparam2').html('')
  $("label[for='fiduceo_retriever_sparam3']").html('')
  $('#fiduceo_retriever_sparam3').html('')
  if window.fiduceo_retriever_id != ""
    if $('#fiduceo_retriever_type').val() == 'provider'
      retriever = window.providers.filter(same_id)[0]
    else
      retriever = window.banks.filter(same_id)[0]

    content = '<abbr title="champ requis">*</abbr> ' + retriever['inputs'][0]['name']
    $("label[for='fiduceo_retriever_login']").html(content)
    if retriever['inputs'][0]['info'] != 'NONE' && retriever['inputs'][0]['info'] != undefined
      $('#fiduceo_retriever_login').attr('placeholder', retriever['inputs'][0]['info'])

    content = '<abbr title="champ requis">*</abbr> ' + retriever['inputs'][1]['name']
    $("label[for='fiduceo_retriever_pass']").html(content)
    if retriever['inputs'][1]['info'] != 'NONE' && retriever['inputs'][1]['info'] != undefined
      $('#fiduceo_retriever_pass').attr('placeholder', retriever['inputs'][1]['info'])

    if retriever['inputs'][2]
      label = '<abbr title="champ requis">*</abbr> ' + retriever['inputs'][2]['name']
      if retriever['inputs'][2]['inputValues'] != undefined
        content = ""
        for option in retriever['inputs'][2]['inputValues']['enumValue']
          content += '<option value="' + option + '">' + option + '</option>'
        $("label[for='fiduceo_retriever_sparam1']").html(label)
        $('#fiduceo_retriever_sparam1').html(content)
        if retriever['inputs'][2]['name'].match(/^caisse$/i) && window.selected_cash_register != null
          $('#fiduceo_retriever_sparam1 option[value="'+(window.selected_cash_register)+'"]').prop('selected', true)
        $('.sparam1').show()
        $('#fiduceo_retriever_param1').val($('#fiduceo_retriever_sparam1').val())
      else
        $("label[for='fiduceo_retriever_param1']").html(label)
        $('.param1').show()
        if retriever['inputs'][2]['info'] != 'NONE' && retriever['inputs'][2]['info'] != undefined
          $('#fiduceo_retriever_param1').attr('placeholder', retriever['inputs'][2]['info'])

    if retriever['inputs'][3]
      label = '<abbr title="champ requis">*</abbr> ' + retriever['inputs'][3]['name']
      if retriever['inputs'][3]['inputValues'] != undefined
        content = ""
        for option in retriever['inputs'][3]['inputValues']['enumValue']
          content += '<option value="' + option + '">' + option + '</option>'
        $("label[for='fiduceo_retriever_sparam2']").html(label)
        $('#fiduceo_retriever_sparam2').html(content)
        if retriever['inputs'][3]['name'].match(/^caisse$/i) && window.selected_cash_register != null
          $('#fiduceo_retriever_sparam2 option[value="'+(window.selected_cash_register)+'"]').prop('selected', true)
        $('.sparam2').show()
        $('#fiduceo_retriever_param2').val($('#fiduceo_retriever_sparam2').val())
      else
        $("label[for='fiduceo_retriever_param2']").html(label)
        $('.param2').show()
        if retriever['inputs'][3]['info'] != 'NONE' && retriever['inputs'][3]['info'] != undefined
          $('#fiduceo_retriever_param2').attr('placeholder', retriever['inputs'][3]['info'])

    if retriever['inputs'][4]
      label = '<abbr title="champ requis">*</abbr> ' + retriever['inputs'][4]['name']
      if retriever['inputs'][4]['inputValues'] != undefined
        content = ""
        for option in retriever['inputs'][4]['inputValues']['enumValue']
          content += '<option value="' + option + '">' + option + '</option>'
        $("label[for='fiduceo_retriever_sparam3']").html(label)
        $('#fiduceo_retriever_sparam3').html(content)
        if retriever['inputs'][4]['name'].match(/^caisse$/i) && window.selected_cash_register != null
          $('#fiduceo_retriever_sparam3 option[value="'+(window.selected_cash_register)+'"]').prop('selected', true)
        $('.sparam3').show()
        $('#fiduceo_retriever_param3').val($('#fiduceo_retriever_sparam3').val())
      else
        $("label[for='fiduceo_retriever_param3']").html(label)
        $('.param3').show()
        if retriever['inputs'][4]['info'] != 'NONE' && retriever['inputs'][4]['info'] != undefined
          $('#fiduceo_retriever_param3').attr('placeholder', retriever['inputs'][4]['info'])
  else
    content = '<abbr title="champ requis">*</abbr> Identifiant'
    $("label[for='fiduceo_retriever_login']").html(content)
    $("#fiduceo_retriever_login").removeAttr('placeholder')

    content = '<abbr title="champ requis">*</abbr> Mot de passe'
    $("label[for='fiduceo_retriever_pass']").html(content)
    $("#fiduceo_retriever_pass").removeAttr('placeholder')

    $('.param1').hide()
    $('.param2').hide()
    $('.param3').hide()
    $('.sparam1').hide()
    $('.sparam2').hide()
    $('.sparam3').hide()
    $('#fiduceo_retriever_param1').removeAttr('placeholder')
    $('#fiduceo_retriever_param2').removeAttr('placeholder')
    $('#fiduceo_retriever_param3').removeAttr('placeholder')

update_selects_list = (show_provider)->
  if show_provider
    $('#fiduceo_retriever_provider_id').parents('.controls').parents('.control-group').show()
    $('#fiduceo_retriever_bank_id').parents('.controls').parents('.control-group').hide()
    $('#fiduceo_retriever_journal_id').parents('.controls').parents('.control-group').show()
  else
    $('#fiduceo_retriever_provider_id').parents('.controls').parents('.control-group').hide()
    $('#fiduceo_retriever_bank_id').parents('.controls').parents('.control-group').show()
    $('#fiduceo_retriever_journal_id').parents('.controls').parents('.control-group').hide()

update_provider = ->
  unless $('#fiduceo_retriever_provider_id').is(':disabled') && $('#fiduceo_retriever_bank_id').is(':disabled')
    result = null
    result = $('#fiduceo_retriever_'+$('#fiduceo_retriever_type').val()+'_id').tokenInput('get')[0]
    if result
      $('#fiduceo_retriever_service_name').val(result.name)
      $('#fiduceo_retriever_name').val(result.name)
      if $('#fiduceo_retriever_type').val() == 'provider'
        url = $.grep(window.providers, (e) -> e.id == result.id)[0]['url']
      else
        url = $.grep(window.banks, (e) -> e.id == result.id)[0]['url']
      if url != undefined && url != null
        link = '<a href="'+url+'" target="_blank">'+url+'</a>'
        help_block = '<p class="help-block"><br/><br/>'+link+'<p>'
        $('#fiduceo_retriever_'+$('#fiduceo_retriever_type').val()+'_id').after(help_block)
    else
      $('#fiduceo_retriever_service_name').val('')
      $('#fiduceo_retriever_name').val('')
      $help_block = $('#fiduceo_retriever_'+$('#fiduceo_retriever_type').val()+'_id').next('p')
      if $help_block != undefined
        $help_block.remove()

jQuery ->
  if $('.retriever_form').length > 0
    window.providers = $('#providers').data('providers')
    window.selected_providers = $('#providers').data('selectedProviders')
    window.banks = $('#banks').data('banks')
    window.selected_banks = $('#banks').data('selectedBanks')
    window.selected_cash_register = $('#banks').data('selectedCashRegister')

    update_selects_list($('#fiduceo_retriever_type').val() == 'provider')

    $('#fiduceo_retriever_type').on 'change', ->
      update_selects_list($(this).val() == 'provider')
      update_form()
      update_provider()

    update_form()

    $('#fiduceo_retriever_sparam1').on 'change', ->
      $('#fiduceo_retriever_param1').val($('#fiduceo_retriever_sparam1').val())
    $('#fiduceo_retriever_sparam2').on 'change', ->
      $('#fiduceo_retriever_param2').val($('#fiduceo_retriever_sparam2').val())
    $('#fiduceo_retriever_sparam3').on 'change', ->
      $('#fiduceo_retriever_param3').val($('#fiduceo_retriever_sparam3').val())

    if $('#fiduceo_retriever_provider_id').is(':disabled')
      $('#fiduceo_retriever_provider_id').addClass('hide')
      $('#fiduceo_retriever_provider_id').after('<input class="string required disabled" disabled="disabled" id="fiduceo_retriever_provider_name" name="fiduceo_retriever[provider_name]" value="'+$('#fiduceo_retriever_service_name').val()+'" type="text">')
    else
      $('#fiduceo_retriever_provider_id').tokenInput window.providers,
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
          update_provider()
        onDelete: (item) ->
          update_form()
          update_provider()

    if $('#fiduceo_retriever_bank_id').is(':disabled')
      $('#fiduceo_retriever_bank_id').addClass('hide')
      $('#fiduceo_retriever_bank_id').after('<input class="string required disabled" disabled="disabled" id="fiduceo_retriever_bank_name" name="fiduceo_retriever[bank_name]" value="'+$('#fiduceo_retriever_service_name').val()+'" type="text">')
    else
      $('#fiduceo_retriever_bank_id').tokenInput window.banks,
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
          update_provider()
        onDelete: (item) ->
          update_form()
          update_provider()

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
        if window.fiduceo_retriever_contains_name != ''
          _url += '&fiduceo_retriever_contains[name]=' + window.fiduceo_retriever_contains_name
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

    window.fiduceo_retriever_contains_name = ''
    window.fiduceo_retrievers_url = 'retrievers?part=true'
    load_retrievers_list()

    $('.retriever_seach.form').on 'submit', (e) ->
      window.fiduceo_retriever_contains_name = $('#fiduceo_retriever_contains_name').val()
      e.preventDefault()
      load_retrievers_list()
    $('.reset_filter').on 'click', (e) ->
      e.preventDefault()
      $('#fiduceo_retriever_contains_name').val('')
      $('#direction').val(null)
      $('#sort').val(null)
      $('#per_page').val(null)
      $('#page').val(null)
      window.fiduceo_retriever_contains_name = ''
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

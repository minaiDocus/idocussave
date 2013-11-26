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
  if window.fiduceo_retriever_id != ""
    if $('#fiduceo_retriever_type').val() == 'provider'
      retriever = window.providers.filter(same_id)[0]
    else
      retriever = window.banks.filter(same_id)[0]

    content = '<abbr title="champ requis">*</abbr> ' + retriever['inputs'][0]['name']
    $("label[for='fiduceo_retriever_login']").html(content)

    content = '<abbr title="champ requis">*</abbr> ' + retriever['inputs'][1]['name']
    $("label[for='fiduceo_retriever_pass']").html(content)

    if retriever['inputs'][2]
      label = '<abbr title="champ requis">*</abbr> ' + retriever['inputs'][2]['name']
      if retriever['inputs'][2]['inputValues'] != undefined
        content = ""
        for option in retriever['inputs'][2]['inputValues']['enumValue']
          content += '<option value="' + option + '">' + option + '</option>'
        $("label[for='fiduceo_retriever_sparam1']").html(label)
        $('#fiduceo_retriever_sparam1').html(content)
        $('.sparam1').show()
      else
        $("label[for='fiduceo_retriever_param1']").html(label)
        $('.param1').show()

    if retriever['inputs'][3]
      label = '<abbr title="champ requis">*</abbr> ' + retriever['inputs'][3]['name']
      if retriever['inputs'][3]['inputValues'] != undefined
        content = ""
        for option in retriever['inputs'][3]['inputValues']['enumValue']
          content += '<option value="' + option + '">' + option + '</option>'
        $("label[for='fiduceo_retriever_sparam2']").html(label)
        $('#fiduceo_retriever_sparam2').html(content)
        $('.sparam2').show()
      else
        $("label[for='fiduceo_retriever_param2']").html(label)
        $('.param2').show()

    if retriever['inputs'][4]
      label = '<abbr title="champ requis">*</abbr> ' + retriever['inputs'][4]['name']
      if retriever['inputs'][4]['inputValues'] != undefined
        content = ""
        for option in retriever['inputs'][4]['inputValues']['enumValue']
          content += '<option value="' + option + '">' + option + '</option>'
        $("label[for='fiduceo_retriever_sparam3']").html(label)
        $('#fiduceo_retriever_sparam3').html(content)
        $('.sparam3').show()
      else
        $("label[for='fiduceo_retriever_param3']").html(label)
        $('.param3').show()
  else
    content = '<abbr title="champ requis">*</abbr> Identifiant'
    $("label[for='fiduceo_retriever_login']").html(content)

    content = '<abbr title="champ requis">*</abbr> Mot de passe'
    $("label[for='fiduceo_retriever_pass']").html(content)

    $('.param1').hide()
    $('.param2').hide()
    $('.param3').hide()
    $('.sparam1').hide()
    $('.sparam2').hide()
    $('.sparam3').hide()

update_selects_list = (show_provider)->
  if show_provider
    $('#fiduceo_retriever_provider_id').parents('.controls').parents('.control-group').show()
    $('#fiduceo_retriever_bank_id').parents('.controls').parents('.control-group').hide()
    $('#fiduceo_retriever_journal_id').parents('.controls').parents('.control-group').show()
  else
    $('#fiduceo_retriever_provider_id').parents('.controls').parents('.control-group').hide()
    $('#fiduceo_retriever_bank_id').parents('.controls').parents('.control-group').show()
    $('#fiduceo_retriever_journal_id').parents('.controls').parents('.control-group').hide()

update_service_name = ->
  unless $('#fiduceo_retriever_provider_id').is(':disabled') && $('#fiduceo_retriever_bank_id').is(':disabled')
    result = null
    result = $('#fiduceo_retriever_'+$('#fiduceo_retriever_type').val()+'_id').tokenInput('get')[0]
    if result
      $('#fiduceo_retriever_service_name').val(result.name)
    else
      $('#fiduceo_retriever_service_name').val('')

jQuery ->
  window.providers = $('#providers').data('providers')
  window.selected_providers = $('#providers').data('selected_providers')
  window.banks = $('#banks').data('banks')
  window.selected_banks = $('#banks').data('selected_banks')

  update_selects_list($('#fiduceo_retriever_type').val() == 'provider')

  $('#fiduceo_retriever_type').on 'change', ->
    update_selects_list($(this).val() == 'provider')
    update_form()
    update_service_name()

  update_form()

  $('#fiduceo_retriever_sparam1').on 'change', ->
    $('#fiduceo_retriever_param1').val($('#fiduceo_retriever_sparam1').val())
  $('#fiduceo_retriever_sparam2').on 'change', ->
    $('#fiduceo_retriever_param2').val($('#fiduceo_retriever_sparam2').val())
  $('#fiduceo_retriever_sparam3').on 'change', ->
    $('#fiduceo_retriever_param3').val($('#fiduceo_retriever_sparam3').val())

  if $('#fiduceo_retriever_provider_id').is(':disabled')
    $('#fiduceo_retriever_provider_id').val($('#fiduceo_retriever_service_name').val())
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
        update_service_name()
      onDelete: (item) ->
        update_form()
        update_service_name()

  if $('#fiduceo_retriever_bank_id').is(':disabled')
    $('#fiduceo_retriever_bank_id').val($('#fiduceo_retriever_service_name').val())
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
        update_service_name()
      onDelete: (item) ->
        update_form()
        update_service_name()
same_id = (element) ->
  element['id'] == window.fiduceo_retriever_id

update_form = ->
  if $('#fiduceo_retriever_type').val() == 'provider'
    window.fiduceo_retriever_id = $('#fiduceo_retriever_provider_id').val()
  else
    window.fiduceo_retriever_id = $('#fiduceo_retriever_bank_id').val()

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
      content = '<abbr title="champ requis">*</abbr> ' + retriever['inputs'][2]['name']
      $("label[for='fiduceo_retriever_param1']").html(content)
      $('.param1').show()
    else
      $('.param1').hide()


    if retriever['inputs'][3]
      content = '<abbr title="champ requis">*</abbr> ' + retriever['inputs'][3]['name']
      $("label[for='fiduceo_retriever_param2']").html(content)
      $('.param2').show()
    else
      $('.param2').hide()

    if retriever['inputs'][4]
      content = '<abbr title="champ requis">*</abbr> ' + retriever['inputs'][4]['name']
      $("label[for='fiduceo_retriever_param3']").html(content)
      $('.param3').show()
    else
      $('.param3').hide()
  else
    content = '<abbr title="champ requis">*</abbr> Identifiant'
    $("label[for='fiduceo_retriever_login']").html(content)

    content = '<abbr title="champ requis">*</abbr> Mot de passe'
    $("label[for='fiduceo_retriever_pass']").html(content)

    $('.param1').hide()
    $('.param2').hide()
    $('.param3').hide()

update_selects_list = (show_provider)->
  if show_provider
    $('#fiduceo_retriever_provider_id').parents('.controls').parents('.control-group').show()
    $('#fiduceo_retriever_bank_id').parents('.controls').parents('.control-group').hide()
  else
    $('#fiduceo_retriever_provider_id').parents('.controls').parents('.control-group').hide()
    $('#fiduceo_retriever_bank_id').parents('.controls').parents('.control-group').show()

jQuery ->
  window.providers = $('#providers').data('providers')
  window.selected_providers = $('#providers').data('selected_providers')
  window.banks = $('#banks').data('banks')
  window.selected_banks = $('#banks').data('selected_banks')

  update_selects_list($('#fiduceo_retriever_type').val() == 'provider')

  $('#fiduceo_retriever_type').on 'change', ->
    update_selects_list($(this).val() == 'provider')
    update_form()

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
    onDelete: (item) ->
      update_form()

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
    onDelete: (item) ->
      update_form()
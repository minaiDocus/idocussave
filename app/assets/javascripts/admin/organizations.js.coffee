jQuery ->
  $('#organization_authd_prev_period').on 'change', ->
    if $(this).val() != '1'
      $('#organization_auth_prev_period_until_day').val(0)
      $('#organization_auth_prev_period_until_month').val(0)

  $('#organization_auth_prev_period_until_day').on 'change', ->
    $('#organization_authd_prev_period').val(1)

  $('#organization_auth_prev_period_until_month').on 'change', ->
    $('#organization_authd_prev_period').val(1)

  $('#organization_leader_id').tokenInput "/admin/users/search_by_code.json?full_info=true",
    theme: "facebook",
    searchDelay: 500,
    minChars: 1,
    tokenLimit: 1,
    preventDuplicates: true,
    prePopulate: $('#doc_group_leader_id').data('pre'),
    hintText: "Tapez un code utilisateur à rechercher",
    noResultsText: "Aucun résultat",
    searchingText: "Recherche en cours..."

  $('#organization_member_tokens').tokenInput "/admin/users/search_by_code.json",
    theme: "facebook",
    searchDelay: 500,
    minChars: 1,
    preventDuplicates: true,
    prePopulate: $('#doc_group_member_tokens').data('pre'),
    hintText: "Tapez un code utilisateur à rechercher",
    noResultsText: "Aucun résultat",
    searchingText: "Recherche en cours..."

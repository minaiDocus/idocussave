jQuery ->
  $('#group_member_tokens').tokenInput "/admin/users/search_by_code.json",
    theme: "facebook",
    searchDelay: 500,
    minChars: 1,
    preventDuplicates: true,
    prePopulate: $('#doc_group_member_tokens').data('pre'),
    hintText: "Tapez un code utilisateur à rechercher",
    noResultsText: "Aucun résultat",
    searchingText: "Recherche en cours..."
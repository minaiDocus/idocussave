jQuery ->
  $('#scanning_provider_customer_tokens').tokenInput "/admin/users/search_by_code.json?full_info=true",
    theme: "facebook",
    searchDelay: 500,
    minChars: 2,
    preventDuplicates: true,
    prePopulate: $('#scanning_provider_customer_tokens').data('pre'),
    hintText: "Tapez un code utilisateur à rechercher",
    noResultsText: "Aucun résultat",
    searchingText: "Recherche en cours..."

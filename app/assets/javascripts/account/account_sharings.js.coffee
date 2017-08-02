jQuery ->
  if $('#account_sharing.new').length > 0
    $('#account_sharing_collaborator_id').tokenInput $('#account_sharing_collaborator_id').data('path'),
      theme: 'facebook',
      minChars: 2,
      tokenLimit: 1,
      preventDuplicates: true,
      hintText: 'Tapez un terme à rechercher',
      noResultsText: 'Aucun résultat',
      searchingText: 'Recherche en cours...'
    $('#account_sharing_account_id').tokenInput $('#account_sharing_account_id').data('path'),
      theme: 'facebook',
      minChars: 2,
      tokenLimit: 1,
      preventDuplicates: true,
      hintText: 'Tapez un terme à rechercher',
      noResultsText: 'Aucun résultat',
      searchingText: 'Recherche en cours...'

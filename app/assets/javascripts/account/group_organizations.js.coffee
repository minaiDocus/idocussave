jQuery ->
  if $('#group_organizations .searchable-option-list').length > 0
    $('#group_organizations .searchable-option-list').searchableOptionList(
      showSelectionBelowList: true,
      showSelectAll: true,
      maxHeight: '300px',
      texts: {
        noItemsAvailable:  'Aucune entrée trouvée',
        selectAll:         'Sélectionner tout',
        selectNone:        'Désélectionner tout',
        quickDelete:       '&times;',
        searchplaceholder: 'Cliquer ici pour rechercher'
      }
    )

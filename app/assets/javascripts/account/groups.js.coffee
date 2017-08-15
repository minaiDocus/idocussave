jQuery ->
  if $('.searchable-option-list').length > 0
    $('.searchable-option-list').searchableOptionList(
      showSelectionBelowList: true,
      showSelectAll: true,
      maxHeight: '300px',
      texts: {
        noItemsAvailable:  'Aucune entrée trouvée',
        selectAll:         "Sélectionner toute l'organisation",
        selectNone:        "Désélectionner toute l'organisation",
        quickDelete:       '&times;',
        searchplaceholder: 'Cliquer ici pour rechercher'
      }
    )

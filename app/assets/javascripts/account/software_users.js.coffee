jQuery ->
  if $('#organizations .edit_software_users .searchable-option-list').length > 0
    $('#organizations .edit_software_users .searchable-option-list').searchableOptionList(
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
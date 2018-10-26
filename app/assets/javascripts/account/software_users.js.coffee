jQuery ->
  if $('#organizations .edit_software_users .searchable-option-list').length > 0
    console.log 'oui'
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
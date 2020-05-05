jQuery ->
  if ($('#importDialog').length > 0)
    $('#importDialog').modal('show')

  $('#importButton').click (e) ->
    if ($('select.piece').val() == '')
      alert('Veuillez sélectionner la colonne pour la pièce de référence svp !')
      return false

  $('.fermer_modal_fec').click (e) ->
    $(this).attr('disabled', true)
    $(this).html('<img src="/assets/application/bar_loading.gif" alt="chargement..." >')

  $('#importButton').click (e) ->
	  $(this).attr('disabled', true)
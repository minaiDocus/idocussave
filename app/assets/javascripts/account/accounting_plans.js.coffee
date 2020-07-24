jQuery ->
  if ($('#import_dialog').length > 0)
    $('#import_dialog').modal('show')

  $('#import_button').click (e) ->
    e.preventDefault();
    $(this).attr('disabled', true)
    if ($('select.piece').val() == '')
      alert('Veuillez sélectionner la colonne pour la référence des pièces svp !')
      $(this).removeAttr('disabled')
      return false
    else
      $('#import_dialog #importFecAfterConfiguration').submit()

  $('.close_modal_fec').click (e) ->
    $(this).attr('disabled', true)
    $(this).html('<img src="/assets/application/bar_loading.gif" alt="chargement..." >')
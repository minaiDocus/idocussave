jQuery ->
  $('.custom_popover').custom_popover()
  $('a.do-showPieces').click (e) ->
    e.defaultPrevented
    $diffDialog = $('#showPieces')
    $diffDialog.find('iframe.duplicate').attr('src', $(this).data('duplicateUrl'))
    $diffDialog.find('iframe.original').attr('src', $(this).data('originalUrl'))
    $diffDialog.modal()
  $('#master_checkbox').change ->
    if $(this).is(':checked')
      $('.checkbox').attr('checked', true);
    else
      $('.checkbox').attr('checked', false);

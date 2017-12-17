jQuery ->
  $('a.do-showPieces').click (e) ->
    e.defaultPrevented
    $diffDialog = $('#showPieces')
    $diffDialog.find('iframe.duplicate').attr('src', $(this).data('duplicateUrl'))
    $diffDialog.find('iframe.original').attr('src', $(this).data('originalUrl'))
    $diffDialog.modal()

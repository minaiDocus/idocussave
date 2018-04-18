jQuery ->
  $('a.do-showPieces').click (e) ->
    e.defaultPrevented
    $showDialog = $('#showPieces')
    $showDialog.find('iframe.piece').attr('src', $(this).data('pieceUrl'))
    $showDialog.find('h3.name').html($(this).data('pieceName'))
    $showDialog.modal()
  $('#master_checkbox').change ->
    if $(this).is(':checked')
      $('.checkbox').attr('checked', true);
    else
      $('.checkbox').attr('checked', false);
check_checker = (index)->
  checker = $('#pre_assignment_ignored .checker_piece_' + index)
  if checker.length > 0
    $('#showPieces #navigation .checkbox_checker').removeClass('hide')
    if checker.is(':checked')
      $('#showPieces #navigation .checkbox_checker').prop('checked', true)
    else
      $('#showPieces #navigation .checkbox_checker').prop('checked', false)
  else
    $('#showPieces #navigation .checkbox_checker').addClass('hide')

load_modal = (el, show)->
  showDialog = $('#showPieces')
  showDialog.find('h3.name').html(el.data('pieceName'))
  showDialog.find('iframe.piece').attr('src', el.data('pieceUrl'))
  if show
    showDialog.modal()

jQuery ->
  currentIndex = 0
  $('.custom_popover').custom_popover()
  $('a.do-showPieces').click (e) ->
    e.defaultPrevented
    currentIndex = $(this).data('pieceIndex')
    check_checker currentIndex
    load_modal $(this), true

  $('#showPieces #navigation a.left').click (e) ->
    e.defaultPrevented
    if currentIndex > 0
      currentIndex -= 1
      check_checker currentIndex
      load_modal $('#pre_assignment_ignored .piece_' + currentIndex), false

  $('#showPieces #navigation a.right').click (e) ->
    e.defaultPrevented
    pieces_count = $('#pre_assignment_ignored a.do-showPieces').length
    if currentIndex < (pieces_count - 1)
      currentIndex += 1
      check_checker currentIndex
      load_modal $('#pre_assignment_ignored .piece_' + currentIndex), false

  $('#master_checkbox').change ->
    if $(this).is(':checked')
      $('.checkbox').prop('checked', true)
    else
      $('.checkbox').prop('checked', false)

  $('#showPieces #navigation .checkbox_checker').change ->
    if $(this).is(':checked')
      $('#pre_assignment_ignored .checker_piece_' + currentIndex).prop('checked', true)
    else
      $('#pre_assignment_ignored .checker_piece_' + currentIndex).prop('checked', false)
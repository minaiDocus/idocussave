jQuery ->
  $('span.popover_active').popover({trigger: 'hover'})

  $('a.do-showAccounts').click (e) ->
    e.preventDefault()
    $accountsDialog = $('#showAccounts')
    $accountsDialog.find('h3').text($(this).attr('title'))
    $accountsDialog.find(".modal-body").html("<span class='loading'>Chargment en cours ...</span>")
    $accountsDialog.modal()
    loadAccounts($(this).attr('type'), $accountsDialog)

loadAccounts = (type, renderer) ->
  $.ajax
    url: "/admin/subscriptions/accounts"
    data: { type: type }
    type: 'POST'
    success: (data) -> renderer.find(".modal-body").html(data)
    error: (data) -> renderer.find(".modal-body").html("<p>Erreur lors du chargement des données, veuillez réessayer plus tard</p>")

$(window).scroll(()->
  topWindow = $(window).scrollTop()
  offset = $('#subscriptions #statistic_table').offset()
  table_position_top = offset.top - topWindow

  if table_position_top > 45
    $('#subscriptions #detachable_header').fadeOut('fast')
  else
    $('#subscriptions #detachable_header').slideDown('fast')
)
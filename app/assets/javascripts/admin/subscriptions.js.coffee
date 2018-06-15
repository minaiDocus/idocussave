jQuery ->
  $('span.popover_active').popover({trigger: 'hover'})

  $('a.do-showAccounts').click (e) ->
    e.preventDefault()
    $accountsDialog = $('#showAccounts')
    $accountsDialog.find('h3').text($(this).attr('title'))
    $accountsDialog.find(".modal-body").html("<span class='loading'>Chargment en cours ...</loading>")
    $accountsDialog.modal()
    loadAccounts($(this).attr('type'), $accountsDialog)


loadAccounts = (type, renderer) ->
  $.ajax
    url: "/admin/subscriptions/accounts"
    data: { type: type }
    type: 'POST'
    success: (data) -> renderer.find(".modal-body").html(data)
    error: (data) -> renderer.find(".modal-body").html("<p>Erreur lors du chargement des données, veuillez réessayer plus tard</p>")
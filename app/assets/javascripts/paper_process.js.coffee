window.year  = -> $('#date_year').val()
window.month = -> $('#date_month').val()
window.day   = -> $('#date_day').val()

jQuery ->
  $('.date select').on 'change', ->
    base = 'kits' if $('#kits').length > 0
    base = 'num'  if $('#num').length > 0
    window.location.href = "/#{base}/#{window.year()}/#{window.month()}/#{window.day()}"

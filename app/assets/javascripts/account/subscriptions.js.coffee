toggle_products = ->
  period_duration = $('#scan_subscription_period_duration').attr('value')
  $('.product').hide()
  $('.product.period_duration_'+period_duration).show()
  $('.product').find('input:first').removeAttr('checked')
  $('.product.period_duration_'+period_duration+':first').find('input:first').attr('checked','checked')

init_prices = (input) ->
  id = $(input).parents('table').attr('id')
  quantity = $(input).parents('tr').find('td .quantity').text()
  $('.depend_on_'+id).each (index, element) ->
    $(element).find('tr').each (i, e) ->
      original_price = $(e).find('.original_price').text()
      new_price = original_price * quantity / 100
      price = (new_price).formatMoney(2,',','.') + " € HT"
      $(e).find('.price label').text(price)

jQuery ->
  if $("#subscriptions.edit, #default_subscriptions.edit, #organization_subscriptions.edit").length > 0
    toggle_products()

    $('#scan_subscription_period_duration').change ->
      toggle_products()

    $('td.input input:checked').each (index, element) ->
      init_prices(element)

    $('td.input input').change ->
      init_prices(this)

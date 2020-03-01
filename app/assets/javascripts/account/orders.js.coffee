paper_set_prices = ->
  JSON.parse($('#paper_set_prices').val())

casing_size_index = ->
  paper_set_casing_size = parseInt($('#order_paper_set_casing_size').val())
  if paper_set_casing_size == 500
    0
  else if paper_set_casing_size == 1000
    1
  else if paper_set_casing_size == 3000
    2

folder_count_index = ->
  parseInt($('#order_paper_set_folder_count').val()) - 5

period_index_of = (start_date, end_date, period_duration) ->
  period_duration = parseInt(period_duration)
  ms_day = 1000*60*60*24*28
  count = Math.floor(Math.abs(end_date - start_date) / ms_day) + period_duration
  (count / period_duration) - 1

discount_price_of = (price) ->
  unit_price = 0
  selected_casing_count = parseInt($('#order_paper_set_casing_count option:selected').text())
  max_casing_count = parseInt($('#order_paper_set_casing_count option').first().text())

  switch(casing_size_index())
    when 0 then unit_price = 6
    when 1 then unit_price = 9
    when 2 then unit_price = 12
    else unit_price = 0

  if(selected_casing_count > 0 && max_casing_count > 0)
    casing_rest = max_casing_count - selected_casing_count
    discount_price = unit_price * casing_rest
    price - discount_price
  else
    price

price_of_periods = ->
  start_date = new Date($('#order_paper_set_start_date').val())
  end_date   = new Date($('#order_paper_set_end_date').val())
  period_index = period_index_of(start_date, end_date, $('#order_period_duration').val())
  if start_date <= end_date
    discount_price_of(paper_set_prices()[casing_size_index()][folder_count_index()][period_index])
  else
    0

update_price = ->
  price = price_of_periods()
  $('.total_price').html(price + ",00€ HT")
  if price == 0
    $('#order_paper_set_start_date').parents('.control-group').addClass('error')
    $('#order_paper_set_start_date').next('.help-inline').remove()
    $("<span class='help-inline'>n\'est pas valide</span>").insertAfter($('#order_paper_set_start_date'))
  else
    $('#order_paper_set_start_date').parents('.control-group').removeClass('error')
    $('#order_paper_set_start_date').next('.help-inline').remove()

update_casing_counts = ->
  start_date = new Date($('#order_paper_set_start_date').val())
  end_date   = new Date($('#order_paper_set_end_date').val())

  if(start_date > 0 && end_date > 0)
    counts = period_index_of(start_date, end_date, $('#order_period_duration').val()) + 1
    options = ''
    curr_val = parseInt($("#paper_set_casing_count_hidden").val()) || 0
    if(curr_val == 0)
      curr_val = counts

    while(counts > 0)
      if(curr_val == counts) then selected = 'selected="selected"' else selected = ''
      options += '<option value="'+counts+'" '+selected+'>' + counts + '</option>'
      counts--

    $('#order_paper_set_casing_count').html(options)
  else
    $('#order_paper_set_casing_count').html('')

  check_casing_size_and_count()

check_casing_size_and_count = ->
  selected_val = parseInt($('#order_paper_set_casing_count option:selected').text())
  max_val = parseInt($('#order_paper_set_casing_count option').first().text())

  $('.casing_count_hint').remove()
  if((max_val - selected_val) >= 2)
    $('#order_paper_set_casing_count').after("<p class='help-block casing_count_hint'>Pour un écart de période important par rapport au nombre d'enveloppes, nous vous conseillons de prendre une enveloppe de taille supérieur à 500g</p>")

jQuery ->
  if $('#order form').length > 0
    update_casing_counts()
    update_price()

    $('select').on 'change', ->
      update_price()

    $('#order_paper_set_start_date, #order_paper_set_end_date').on 'change', ->
      update_casing_counts()

    $('#order_paper_set_casing_count').on 'change', ->
      check_casing_size_and_count()

    $('.copy_address').on 'click', (e) ->
      e.preventDefault()
      $('#order_paper_return_address_attributes_company').val($('#order_address_attributes_company').val())
      $('#order_paper_return_address_attributes_last_name').val($('#order_address_attributes_last_name').val())
      $('#order_paper_return_address_attributes_first_name').val($('#order_address_attributes_first_name').val())
      $('#order_paper_return_address_attributes_address_1').val($('#order_address_attributes_address_1').val())
      $('#order_paper_return_address_attributes_address_2').val($('#order_address_attributes_address_2').val())
      $('#order_paper_return_address_attributes_city').val($('#order_address_attributes_city').val())
      $('#order_paper_return_address_attributes_zip').val($('#order_address_attributes_zip').val())

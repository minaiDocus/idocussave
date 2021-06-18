paper_set_prices = ->
  JSON.parse($('#paper_set_prices').val())

is_manual_paper_set_order_applied = ->
  manual_paper_set_order = $('#paper_set_specific_prices')
  manual_paper_set_order.length > 0 && manual_paper_set_order.attr("data-manual") == 'true'

casing_size_index_of = (size) ->
  paper_set_casing_size = parseInt(size)
  if paper_set_casing_size == 500
    0
  else if paper_set_casing_size == 1000
    1
  else if paper_set_casing_size == 3000
    2

folder_count_index = ->
  parseInt($('#order_paper_set_folder_count, #orders__paper_set_folder_count').val()) - 5

period_index_of = (start_date, end_date, period_duration) ->
  period_duration = parseInt(period_duration)
  ms_day = 1000*60*60*24*28
  count = Math.floor(Math.abs(end_date - start_date) / ms_day) + period_duration
  (count / period_duration) - 1


discount_price_of = (price, size, tr_index) ->
  unit_price = 0
  if(tr_index < 0)
    selected_casing_count = parseInt($('#order_paper_set_casing_count option:selected').text())
    max_casing_count = parseInt($('#order_paper_set_casing_count option').first().text())
  else
    selected_casing_count = parseInt($('.casing_count_'+tr_index+' option:selected').text())
    max_casing_count = parseInt($('.casing_count_'+tr_index+' option').first().text())

  switch(casing_size_index_of(size))
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
  size = $('#order_paper_set_casing_size').val()
  start_date = new Date($('#order_paper_set_start_date').val())
  end_date   = new Date($('#order_paper_set_end_date').val())
  period_index = period_index_of(start_date, end_date, $('#order_period_duration').val())

  if start_date <= end_date
    if is_manual_paper_set_order_applied()
      paper_set_folder_count = parseInt($("input[name*='paper_set_folder_count']").val())
      paper_set_folder_count * (period_index + 1)
    else
      discount_price_of(paper_set_prices()[casing_size_index_of(size)][folder_count_index()][period_index], size, -1)
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
      selected=''
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

update_table_price = ->
  orders = $('#paper_set_orders.order_multiple tbody tr')
  total_price = 0
  for order in orders
    do (order) ->
      paper_set_casing_size  = parseInt($(order).find("select[name*='paper_set_casing_size']").val())
      paper_set_folder_count_index = parseInt($(order).find("select[name*='paper_set_folder_count']").val()) - 5
      start_date = new Date($(order).find("select[name*='paper_set_start_date']").val())
      end_date = new Date($(order).find("select[name*='paper_set_end_date']").val())
      period_index = period_index_of(start_date, end_date , $(order).find("input[name*='period_duration']").val())
      if start_date <= end_date
        if is_manual_paper_set_order_applied()
          folder_count = parseInt($(order).find("input[name*='paper_set_folder_count']").val())
          price = folder_count * (period_index + 1)
        else
          price = discount_price_of(paper_set_prices()[casing_size_index_of(paper_set_casing_size)][paper_set_folder_count_index][period_index], paper_set_casing_size, $(order).attr('data-index'))
          $(order).find("select[name*='paper_set_start_date']").parents('.control-group').removeClass('error')
          $(order).find("select[name*='paper_set_start_date']").next('.help-inline').remove()
      else
        price = 0
        $(order).find("select[name*='paper_set_start_date']").parents('.control-group').addClass('error')
        $(order).find("select[name*='paper_set_start_date']").next('.help-inline').remove()
        $("<span class='help-inline'>n\'est pas valide</span>").insertAfter($(order).find("select[name*='paper_set_start_date']"))
      total_price += price
      $(order).find('.price').html(price + ",00€")
      $('.total_price').html(total_price + ",00€ HT")

update_table_casing_counts = (index)->
  monthDiff = (dateFrom, dateTo) ->
    return (dateTo.getMonth() - dateFrom.getMonth() + (12 * (dateTo.getFullYear() - dateFrom.getFullYear()))) + 1

  fill_options_of = (ind) ->
    start_date = new Date($('.date_order.start_date_'+ind).val())
    end_date = new Date($('.date_order.end_date_'+ind).val())

    if(start_date > 0 && end_date > 0)
      counts = period_index_of(start_date, end_date, $('.period_duration_'+ind).val()) + 1
      options = ''
      selected = 'selected="selected"'

      while(counts > 0)
        options += '<option value="'+counts+'" '+selected+'>' + counts + '</option>'
        selected=''
        counts--

      $('.casing_count_'+ind).html(options)
    else
      $('.casing_count_'+ind).html('')

  if(index < 0)
    $('#paper_set_orders.order_multiple tbody#list_orders > tr').each((e)->
      key = $(this).attr("data-index")
      fill_options_of(key)
    )
  else
    fill_options_of(index)

  # check_table_casing_size_and_count()

# check_table_casing_size_and_count = ->
#   selected_val = parseInt($('#order_paper_set_casing_count option:selected').text())
#   max_val = parseInt($('#order_paper_set_casing_count option').first().text())

#   $('.casing_count_hint').remove()
#   if((max_val - selected_val) >= 2)
#     $('#order_paper_set_casing_count').after("<p class='help-block casing_count_hint'>Pour un écart de période important par rapport au nombre d'enveloppes, nous vous conseillons de prendre une enveloppe de taille supérieur à 500g</p>")


confirm_manual_paper_set_order = ->
  if is_manual_paper_set_order_applied()
    $('.valid-manual-paper-set-order').on 'click', (e) ->
      e.preventDefault()
      if confirm("Vous êtes sur le point de commander un kit sans passer par courrier. Etes-vous sûr ?")
        $('#valid-manual-paper-set-order').submit()


jQuery ->
  if $('#paper_set_order form').length > 0
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

    confirm_manual_paper_set_order()

  if $('#paper_set_orders.select_to_order').length > 0
    $('#master_checkbox').change ->
      if $(this).is(':checked')
        $('.checkbox').attr('checked', true);
      else
        $('.checkbox').attr('checked', false);

  if $('.order_multiple form').length > 0
    update_table_casing_counts(-1)
    update_table_price()

    $('select').on 'change', ->
      update_table_price()

    $('.date_order').on 'change', ->
      index = $(this).attr("data-index")
      update_table_casing_counts(index)

    # $('#order_paper_set_casing_count').on 'change', ->
    #   check_table_casing_size_and_count()

    confirm_manual_paper_set_order()


paper_set_prices = ->
  [
    [
      [26, 34, 43, 51, 59, 67, 76, 84, 37, 100, 109, 117, 128, 136, 144, 153, 161, 169, 177, 186, 194, 202, 211, 219],
      [26, 34, 43, 51, 59, 68, 76, 84, 93, 101, 112, 121, 129, 137, 146, 154, 162, 171, 179, 187, 196, 204, 212, 221],
      [26, 35, 43, 51, 60, 68, 77, 85, 93, 105, 113, 121, 130, 138, 147, 155, 163, 172, 180, 189, 197, 206, 214, 222],
      [26, 35, 43, 52, 60, 69, 77, 86, 97, 105, 114, 122, 131, 139, 148, 156, 165, 173, 182, 190, 199, 207, 216, 224],
      [26, 35, 43, 52, 61, 69, 78, 89, 97, 106, 115, 123, 132, 140, 149, 157, 166, 175, 183, 192, 200, 209, 217, 226],
      [26, 35, 44, 52, 61, 70, 81, 90, 98, 107, 115, 124, 133, 141, 150, 159, 167, 176, 184, 193, 202, 210, 219, 228]
    ],
    [
      [30, 42, 53, 64, 75, 86, 97, 108, 119, 131, 142, 153, 167, 178, 189, 200, 211, 223, 234, 245, 256, 267, 278, 289],
      [30, 42, 53, 64, 75, 87, 98, 109, 120, 131, 146, 157, 168, 179, 190, 202, 213, 224, 235, 246, 258, 269, 280, 291],
      [31, 42, 53, 64, 76, 87, 98, 110, 121, 135, 146, 158, 169, 180, 192, 203, 214, 225, 237, 248, 259, 271, 282, 293],
      [31, 42, 53, 65, 76, 87, 99, 110, 124, 136, 147, 159, 170, 181, 193, 204, 216, 227, 238, 250, 261, 272, 284, 295],
      [31, 42, 54, 65, 77, 88, 99, 114, 125, 137, 148, 160, 171, 183, 194, 205, 217, 228, 240, 251, 263, 274, 286, 297],
      [31, 42, 54, 65, 77, 88, 103, 114, 126, 137, 149, 161, 172, 184, 195, 207, 218, 230, 241, 253, 264, 276, 287, 299]
    ],
    [
      [32, 46, 59, 73, 86, 100, 113, 127, 141, 154, 168, 181, 198, 211, 225, 238, 252, 265, 279, 292, 306, 319, 333, 347],
      [32, 46, 59, 73, 87, 100, 114, 128, 141, 155, 171, 185, 199, 212, 226, 239, 253, 267, 280, 294, 308, 321, 335, 348],
      [32, 46, 60, 73, 87, 101, 114, 128, 142, 158, 172, 186, 200, 213, 227, 241, 254, 268, 282, 295, 309, 323, 337, 350],
      [32, 46, 60, 74, 87, 101, 115, 129, 145, 159, 173, 187, 201, 214, 228, 242, 256, 269, 283, 297, 311, 325, 338, 352],
      [32, 46, 60, 74, 88, 102, 116, 132, 146, 160, 174, 188, 202, 215, 229, 243, 257, 271, 285, 299, 312, 326, 340, 354],
      [33, 46, 60, 74, 88, 102, 119, 133, 147, 161, 175, 189, 203, 216, 230, 244, 258, 272, 286, 300, 314, 328, 342, 356]
    ]
  ]

casing_size_index_of = (size) ->
  paper_set_casing_size = parseInt(size)
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
  ms_day = 1000*60*60*24*30
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


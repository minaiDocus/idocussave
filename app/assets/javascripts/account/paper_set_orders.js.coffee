paper_set_prices = ->
  [
    [
      [25, 33, 41, 48, 56, 64, 72, 80, 88, 96,  103, 111, 122, 130, 138, 145, 153, 161, 169, 177, 185, 193, 201, 208],
      [25, 33, 41, 49, 57, 65, 72, 80, 88, 96,  107, 115, 123, 131, 139, 147, 154, 162, 170, 178, 186, 194, 202, 210],
      [25, 33, 41, 49, 57, 65, 73, 81, 89, 100, 108, 116, 124, 132, 140, 148, 156, 164, 172, 180, 188, 196, 204, 212],
      [25, 33, 41, 49, 57, 65, 73, 82, 92, 100, 108, 116, 125, 133, 141, 149, 157, 165, 173, 181, 189, 197, 205, 213],
      [25, 33, 41, 50, 58, 66, 74, 85, 93, 101, 109, 117, 125, 134, 142, 150, 158, 166, 174, 183, 191, 199, 207, 215],
      [25, 33, 42, 50, 58, 66, 77, 85, 93, 102, 110, 118, 126, 135, 143, 151, 159, 167, 176, 184, 192, 200, 209, 217]
    ],
    [
      [29, 40, 50, 61, 71, 82, 93, 103, 114, 124, 135, 146, 159, 170, 180, 191, 201, 212, 223, 233, 244, 254, 265, 276],
      [29, 40, 50, 61, 72, 82, 93, 104, 114, 125, 139, 149, 160, 171, 181, 192, 203, 213, 224, 235, 245, 256, 267, 277],
      [29, 40, 51, 61, 72, 83, 94, 104, 115, 129, 139, 150, 161, 172, 182, 193, 204, 215, 225, 236, 247, 258, 268, 279],
      [29, 40, 51, 62, 72, 83, 94, 105, 118, 129, 140, 151, 162, 173, 184, 194, 205, 216, 227, 238, 249, 259, 270, 281],
      [29, 40, 51, 62, 73, 84, 95, 108, 119, 130, 141, 152, 163, 174, 185, 196, 207, 217, 228, 239, 250, 261, 272, 283],
      [29, 40, 51, 62, 73, 84, 98, 109, 120, 131, 142, 153, 164, 175, 186, 197, 208, 219, 230, 241, 252, 263, 274, 285]
    ],
    [
      [31, 43, 56, 69, 82, 95, 108, 121, 134, 147, 160, 173, 188, 201, 214, 227, 240, 253, 266, 278, 291, 304, 317, 330],
      [31, 44, 57, 70, 83, 96, 109, 122, 134, 147, 163, 176, 189, 202, 215, 228, 241, 254, 267, 280, 293, 306, 319, 332],
      [31, 44, 57, 70, 83, 96, 109, 122, 135, 151, 164, 177, 190, 203, 216, 229, 242, 255, 268, 281, 294, 308, 321, 334],
      [31, 44, 57, 70, 83, 96, 110, 123, 138, 152, 165, 178, 191, 204, 217, 230, 243, 257, 270, 283, 296, 309, 322, 335],
      [31, 44, 57, 70, 84, 97, 110, 126, 139, 152, 166, 179, 192, 205, 218, 232, 245, 258, 271, 284, 298, 311, 324, 337],
      [31, 44, 58, 71, 84, 97, 113, 127, 140, 153, 166, 180, 193, 206, 219, 233, 246, 259, 273, 286, 299, 312, 326, 339]
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

price_of_periods = ->
  size = $('#order_paper_set_casing_size').val()
  start_date = new Date($('#order_paper_set_start_date').val())
  end_date   = new Date($('#order_paper_set_end_date').val())
  period_index = period_index_of(start_date, end_date, $('#order_period_duration').val())
  if start_date <= end_date
    paper_set_prices()[casing_size_index_of(size)][folder_count_index()][period_index]
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
        price = paper_set_prices()[casing_size_index_of(paper_set_casing_size)][paper_set_folder_count_index][period_index]
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

jQuery ->
  if $('#paper_set_order form').length > 0
    update_price()

    $('select').on 'change', ->
      update_price()

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
    update_table_price()

    $('select').on 'change', ->
      update_table_price()




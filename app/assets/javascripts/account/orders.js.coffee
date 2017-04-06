paper_set_prices = ->
  [
    [
      [21, 28, 35, 42, 48, 55, 62, 69, 76, 82, 89,  96, 105, 112, 118, 125, 132, 139, 146, 152, 159, 166, 173, 179],
      [21, 28, 35, 42, 49, 56, 62, 69, 76, 83, 92,  99, 106, 112, 119, 126, 133, 140, 147, 154, 160, 167, 174, 181],
      [21, 28, 35, 42, 49, 56, 63, 70, 77, 86, 93, 100, 106, 113, 120, 127, 134, 141, 148, 155, 162, 169, 175, 182],
      [22, 28, 35, 42, 49, 56, 63, 70, 79, 86, 93, 100, 107, 114, 121, 128, 135, 142, 149, 156, 163, 170, 177, 184],
      [22, 29, 36, 43, 50, 57, 64, 73, 80, 87, 94, 101, 108, 115, 122, 129, 136, 143, 150, 157, 164, 171, 178, 185],
      [22, 29, 36, 43, 50, 57, 66, 73, 80, 88, 95, 102, 109, 116, 123, 130, 137, 144, 151, 158, 165, 173, 180, 187]
    ],
    [
      [23, 31, 40, 48, 57, 65, 73, 82, 90,  99, 107, 116, 126, 135, 143, 151, 160, 168, 177, 185, 193, 202, 210, 219],
      [23, 31, 40, 48, 57, 65, 74, 82, 91,  99, 110, 118, 127, 135, 144, 152, 161, 169, 178, 186, 195, 203, 212, 220],
      [23, 32, 40, 49, 57, 66, 74, 83, 91, 102, 111, 119, 128, 136, 145, 153, 162, 170, 179, 187, 196, 205, 213, 222],
      [23, 32, 40, 49, 58, 66, 75, 83, 94, 103, 111, 120, 128, 137, 146, 154, 163, 171, 180, 189, 197, 206, 214, 223],
      [23, 32, 41, 49, 58, 66, 75, 86, 95, 103, 112, 121, 129, 138, 147, 155, 164, 173, 181, 190, 199, 207, 216, 225],
      [23, 32, 41, 49, 58, 67, 78, 86, 95, 104, 113, 121, 130, 139, 148, 156, 165, 174, 182, 191, 200, 209, 217, 226]
    ],
    [
      [25, 36, 46, 57, 68, 78, 89,  99, 110, 121, 131, 142, 155, 165, 176, 187, 197, 208, 218, 229, 240, 250, 261, 272],
      [25, 36, 47, 57, 68, 79, 89, 100, 111, 121, 134, 145, 156, 166, 177, 188, 198, 209, 220, 230, 241, 252, 262, 273],
      [25, 36, 47, 57, 68, 79, 90, 100, 111, 124, 135, 146, 156, 167, 178, 189, 199, 210, 221, 231, 242, 253, 264, 274],
      [25, 36, 47, 58, 69, 79, 90, 101, 114, 125, 136, 146, 157, 168, 179, 189, 200, 211, 222, 233, 243, 254, 265, 276],
      [25, 36, 47, 58, 69, 80, 91, 104, 114, 125, 136, 147, 158, 169, 180, 190, 201, 212, 223, 234, 245, 256, 266, 277],
      [25, 36, 47, 58, 69, 80, 93, 104, 115, 126, 137, 148, 159, 170, 181, 191, 202, 213, 224, 235, 246, 257, 268, 279]
    ]
  ]

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
  ms_day = 1000*60*60*24*30
  count = Math.floor(Math.abs(end_date - start_date) / ms_day) + period_duration
  (count / period_duration) - 1

price_of_periods = ->
  start_date = new Date($('#order_paper_set_start_date').val())
  end_date   = new Date($('#order_paper_set_end_date').val())
  period_index = period_index_of(start_date, end_date, $('#order_period_duration').val())
  if start_date <= end_date
    paper_set_prices()[casing_size_index()][folder_count_index()][period_index]
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

jQuery ->
  if $('#order form').length > 0
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

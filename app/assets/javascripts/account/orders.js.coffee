paper_set_prices = ->
  [
    [
      [27, 36, 44, 53, 62, 70, 79, 88, 96, 105, 113, 122, 133, 142, 151, 159, 168, 177, 185, 194, 202, 211, 220, 228],
      [27, 36, 45, 53, 62, 71, 79, 88, 97, 106, 117, 126, 134, 143, 152, 161, 169, 178, 187, 195, 204, 213, 222, 230],
      [27, 36, 45, 54, 62, 71, 80, 89, 98, 109, 118, 127, 135, 144, 153, 162, 171, 179, 188, 197, 206, 215, 223, 232],
      [27, 36, 45, 54, 63, 72, 81, 89, 101, 110, 119, 128, 136, 145, 154, 163, 172, 181, 190, 198, 207, 216, 225, 234],
      [27, 36, 45, 54, 63, 72, 81, 93, 102, 111, 120, 129, 137, 146, 155, 164, 173, 182, 191, 200, 209, 218, 227, 236],
      [28, 37, 46, 55, 64, 73, 84, 93, 102, 111, 120, 129, 138, 147, 157, 166, 175, 184, 193, 202, 211, 220, 229, 238]
    ],
    [
      [32, 43, 55, 67, 78, 90, 102, 113, 125, 137, 148, 160, 175, 186, 198, 210, 221, 233, 245, 256, 268, 280, 291, 303],
      [32, 44, 55, 67, 79, 91, 102, 114, 126, 138, 152, 164, 176, 188, 199, 211, 223, 235, 246, 258, 270, 282, 293, 305],
      [32, 44, 56, 67, 79, 91, 103, 115, 127, 141, 153, 165, 177, 189, 201, 212, 224, 236, 248, 260, 272, 283, 295, 307],
      [32, 44, 56, 68, 80, 92, 104, 115, 130, 142, 154, 166, 178, 190, 202, 214, 226, 238, 250, 261, 273, 285, 297, 309],
      [32, 44, 56, 68, 80, 92, 104, 119, 131, 143, 155, 167, 179, 191, 203, 215, 227, 239, 251, 263, 275, 287, 299, 311],
      [32, 44, 56, 68, 81, 93, 108, 120, 132, 144, 156, 168, 180, 192, 204, 216, 229, 241, 253, 265, 277, 289, 301, 313]
    ],
    [
      [33, 47, 61, 75, 89, 103, 117, 131, 145, 159, 173, 187, 204, 218, 232, 246, 260, 274, 288, 302, 316, 330, 344, 358],
      [33, 47, 61, 75, 90, 104, 118, 132, 146, 160, 177, 191, 205, 219, 233, 247, 261, 275, 289, 303, 317, 332, 346, 360],
      [33, 47, 62, 76, 90, 104, 118, 132, 146, 164, 178, 192, 206, 220, 234, 248, 263, 277, 291, 305, 319, 333, 347, 362],
      [33, 48, 62, 76, 90, 105, 119, 133, 150, 164, 179, 193, 207, 221, 235, 250, 264, 278, 292, 307, 321, 335, 349, 364],
      [33, 48, 62, 76, 91, 105, 119, 137, 151, 165, 179, 194, 208, 222, 237, 251, 265, 280, 294, 308, 322, 337, 351, 365],
      [34, 48, 62, 77, 91, 105, 123, 137, 152, 166, 180, 195, 209, 223, 238, 252, 267, 281, 295, 310, 324, 339, 353, 367]
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

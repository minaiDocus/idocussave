jQuery ->
  $('.onglets').on 'click', (e) ->
    e.preventDefault()
    $('.body_table').addClass('hide').removeClass('active')
    $("."+$(this).attr('id')+"_table").removeClass('hide').addClass('active')
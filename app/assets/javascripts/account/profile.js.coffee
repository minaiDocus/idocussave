apply_services_numbers_limit = ->
  services_used_count = $(".use_service:checked").length
  if (services_used_count < 2)
    $(".use_service:not(:checked)").removeAttr("disabled")
  else if services_used_count == 2
    $(".use_service:not(:checked)").attr("disabled","disabled")

update_path_preview = (element) ->
  service = element.closest("[class*='service_config_']").attr("class").split("_")[2]
  path = ''
  if service == '2'
    path += 'Applications > iDocus > '
  path += element.val()
  path = path.replace(':code', 'CODE%001')
  path = path.replace(':year', '2017')
  path = path.replace(':month', '01')
  path = path.replace(':account_book', 'AC')
  path = path.replace(/\//g, ' > ')
  path = path.replace(/>\W$/, '')
  element.parent().parent().parent().parent().find("#storage_final_path").val(path)

jQuery ->
  apply_services_numbers_limit()

  $(".use_service").each ->
    service = $(this).attr("id").split("_")[1]
    if $(this).is(":checked")
      $(".service_config_"+service).show()
    else
      $(".service_config_"+service).hide()

  # external file storage management
  $(".use_service").change ->
    service = $(this).attr("id").split("_")[1]
    is_enable = false
    if $(this).is(":checked")
      is_enable = true
      $(".service_config_"+service).show()
    else
      $(".service_config_"+service).hide()
    hsh = {service: service, is_enable: is_enable}
    $.ajax
      url: "/account/external_file_storage/use",
      data: hsh,
      dataType: "json",
      type: "POST",
      success: (data) ->
        if data
          $(".alerts").html("<div class='row-fluid'><div class='span12 alert alert-success'><a class='close' data-dismiss='alert'> × </a><span> Votre modification a été enregistrée.</span></div></div>")
          if is_enable
            $(".service_config_"+service).show()
          else
            $(".service_config_"+service).hide()
        else
          $(".alerts").html("<div class='row-fluid'><div class='span12 alert alert-error'><a class='close' data-dismiss='alert'> × </a><span> Cette opération est non autorisée.</span></div></div>")
    apply_services_numbers_limit()

  $(".do-show").click ->
    id = $(this).attr('href')
    $('.dlink li').removeClass('active')
    $(this).parent('li').addClass('active')

    $('.pan').removeClass('active')
    $(id).addClass('active')
    return false

  $("#user_notify_attributes_to_send_docs").change ->
    if !$(this).is(":checked")
      str_origin = "En décochant cette case, vous demandez à ne plus recevoir de mails automatiques de relance pour l'envoi de vos documents papier à iDocus.\nAfin de bénéficier pleinement du service, nous vous conseillons de respecter les dates préconisées par votre cabinet."
      encode_utf8 = unescape( encodeURIComponent( str_origin ) )
      result = confirm(encode_utf8)
      if result == false
        $(this).attr('checked', true)

  if $('.storage_form').length > 0
    update_path_preview($('#dropbox_basic_path'))
    update_path_preview($('#google_doc_path'))
    update_path_preview($('#ftp_path'))
    update_path_preview($('#sftp_path'))
    update_path_preview($('#box_path'))

    $('#dropbox_basic_path, #google_doc_path, #ftp_path, #sftp_path, #box_path').on 'change', ->
      update_path_preview($(this))

  $('.do-popover').popover()

  # Scroll down by 50px to avoid content being hidden by top menu when there is an anchor
  shiftWindow = -> scrollBy(0, -50)
  isAtTheBottomOfThePage = -> $(window).scrollTop() == $(document).height()-$(window).height()
  window.addEventListener('hashchange', shiftWindow)
  if window.location.hash && !isAtTheBottomOfThePage()
    shiftWindow()

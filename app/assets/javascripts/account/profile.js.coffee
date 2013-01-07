apply_services_numbers_limit = ->
  services_used_count = $(".use_service:checked").length
  if (services_used_count < 2)
    $(".use_service:not(:checked)").removeAttr("disabled")
  else if services_used_count == 2
    $(".use_service:not(:checked)").attr("disabled","disabled")

jQuery ->
  apply_services_numbers_limit()

  # payment mode management
  $("input[type=radio]").click ->
    request_value = 0
    if $(this).val() == "false"
      request_value = 1
    else
      request_value = 2
    hsh = {mode: request_value}
    $.ajax
      url: "/account/payment/mode",
      data: hsh,
      dataType: "json",
      type: "POST",
      success: (data) ->
        if data == 1
          $(".alerts").html("<div class='row-fluid'><div class='span12 alert alert-success'><a class='close' data-dismiss='alert'> × </a><span> Vos réglements seront maintenant débités de votre compte prépayé.</span></div></div>")
        else if data == 2
          $(".alerts").html("<div class='row-fluid'><div class='span12 alert alert-success'><a class='close' data-dismiss='alert'> × </a><span> Vos réglements seront maintenant prélevés sur votre compte bancaire.</span></div></div>")
        else if data == 3
          $(".alerts").html("<div class='row-fluid'><div class='span12 alert alert-info'><a class='close' data-dismiss='alert'> × </a><span> Vous n'avez pas encore configuré votre prélèvement.</span></div></div>")
          $("#prlv").attr('checked', false)
          $("#pp").attr('checked', true)
        else
          $(".alerts").html("<div class='row-fluid'><div class='span12 alert alert-error'><a class='close' data-dismiss='alert'> × </a><span> Une erreur est survenue, veuillez réessayer s'il vous plaît.</span></div></div>")
  
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
          $(".alerts").html("<div class='row-fluid'><div class='span12 alert alert-success'><a class='close' data-dismiss='alert'> × </a><span> Vos modification ont été enregistrée.</span></div></div>")
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

  $("#user_is_reminder_email_active").change ->
    if !$(this).is(":checked")
      result = confirm("En décochant cette case, vous demandez à ne plus recevoir de mails automatiques de relance pour l'envoi de vos documents papier à iDocus.\nAfin de bénéficier pleinement du service, nous vous conseillons de respecter les dates préconisées par votre cabinet.")
      if result == false
        $(this).attr('checked', true)

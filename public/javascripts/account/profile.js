function apply_services_numbers_limit(){
  services_used_count = $(".use_service:checked").length;
  if (services_used_count < 2){
    $(".use_service:not(:checked)").removeAttr("disabled");
  } else if (services_used_count == 2){
    $(".use_service:not(:checked)").attr("disabled","disabled");
  }
}

if (is_path_used){
  $(".global_path").removeAttr("disabled");
  $(".other_path").attr("disabled","disabled");
} else {
  $(".global_path").attr("disabled","disabled");
  $(".other_path").removeAttr("disabled");
}

$(document).ready(function(){
  apply_services_numbers_limit()

  // payment mode management
  $("input[type=radio]").click(function(){
    var request_value = 0;
    if ($(this).val() == "false")
      request_value = 1;
    else
      request_value = 2;
    hsh = {mode: request_value};
    $.ajax({
      url: "/account/payment/mode",
      data: hsh,
      dataType: "json",
      type: "POST",
      beforeSend: function() {
      },
      success: function(data){
        if (data == "1"){
          $(".alerts").html("<div class='alert alert-success'><a class='close' data-dismiss='alert'> × </a><span> Vos réglements seront maintenant débités de votre compte prépayé.</span></div>");
        } else if (data == "2"){
          $(".alerts").html("<div class='alert alert-success'><a class='close' data-dismiss='alert'> × </a><span> Vos réglements seront maintenant prélevés sur votre compte bancaire.</span></div>");
        } else if (data == "3"){
          $(".alerts").html("<div class='alert alert-info'><a class='close' data-dismiss='alert'> × </a><span> Vous n'avez pas encore configuré votre prélèvement.</span></div>");
          $("#prlv").attr('checked', false);
          $("#pp").attr('checked', true);
        } else {
          $(".alerts").html("<div class='alert alert-error'><a class='close' data-dismiss='alert'> × </a><span> Une erreur est survenue, veuillez réessayer s'il vous plaît.</span></div>");
        }
      }
    });
  });
  
  // external file storage management
  $(".use_service").change(function(){
    var service = $(this).attr("id").split("_")[1];
    var is_enable = false;
    if ($(this).is(":checked")) {
      is_enable = true;
      $(".service_config_"+service).show();
    } else {
      $(".service_config_"+service).hide();
    }
    hsh = {service: service, is_enable: is_enable};
    $.ajax({
      url: "/account/external_file_storage/use",
      data: hsh,
      dataType: "json",
      type: "POST",
      beforeSend: function(){
      },
      success: function(data){
        if (data == true){
          $(".alerts").html("<div class='alert alert-success'><a class='close' data-dismiss='alert'> × </a><span> Vos modification ont été enregistrée.</span></div>");
          if (is_enable)
            $(".service_config_"+service).show();
          else
            $(".service_config_"+service).hide();
        } else if (data == false){
          $(".alerts").html("<div class='alert alert-error'><a class='close' data-dismiss='alert'> × </a><span> Cette opération est non autorisée.</span></div>");
        }
      }
    });
    apply_services_numbers_limit();
  });
  
  $("#use_global_path").change(function(){
    is_path_used = $(this).is(":checked");
    if (is_path_used){
      $(".global_path").removeAttr("disabled");
      $(".other_path").attr("disabled","disabled");
    } else {
      $(".global_path").attr("disabled","disabled");
      $(".other_path").removeAttr("disabled");
    }
    var hsh = {"external_file_storage[is_path_used]": is_path_used};
    $.ajax({
      url: "/account/external_file_storage/update_path_settings",
      data: hsh,
      dataType: "json",
      type: "POST",
      beforeSend: function(){
      },
      success: function(data){
        if (data == "1") {
          $(".alerts").html("<div class='alert alert-success'><a class='close' data-dismiss='alert'> × </a><span>Modifié avec succès.</span></div>");
        } else {
          $(".alerts").html("<div class='alert alert-error'><a class='close' data-dismiss='alert'> × </a><span>Une erreur est suvenu lors de la modification, veuillez réessayer plus tard.</span></div>");
        }
      }
    });
  });
});

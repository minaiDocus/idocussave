$(document).ready(function(){
  $("#view_for").change(function(){
    id = $(this).val();
    
    $(".user").hide();
    $(".total").hide();
    
    if(id == 0) {
      if ($(".do-showHideGlobal.users").is(":checked")) {
        $(".do-showHideGlobal").attr("disabled",false);
      } else {
        $(".do-showHideGlobal.users").attr("disabled",false);
      }
      
      $(".do-showHideInformation.users").each(function(index){
        var $this = $(this);
        var mois = $this.attr("id").split("_")[1];
        $this.removeAttr("disabled");
        if ($this.is(":checked")) {
          $("#subscriptions_"+mois).attr("disabled",false);
          $(".month_"+mois+" .user").show();
          $(".month_"+mois+" .total").show();
        } else {
          $(".month_"+mois+" .total").show();
        }
      });
    } else {
      $(".user_"+id).show();
      $(".do-showHideInformation").attr("disabled",true);
      $(".do-showHideGlobal").attr("disabled",true);
    }
  });
  
  $(".do-showThis").click(function(){
    $(this).hide();
    $(this).parents(".actiongroup").children(".do-hideThis").show();
    $(this).parents(".header").next(".content").show();
  });
  
  $(".do-hideThis").click(function(){
    $(this).hide();
    $(this).parents(".actiongroup").children(".do-showThis").show();
    $(this).parents(".header").next(".content").hide();
  });
  
  $(".do-showHideInformation").change(function(){
    var mois = $(this).attr("id").split("_")[1];
    var $subscriptions = $("#subscriptions_"+mois);
    var is_subs_info_checked = $subscriptions.is(":checked");
    var is_users_info_checked = $("#users_"+mois).is(":checked");
    
    if (is_subs_info_checked) {
      $(".subscription_"+mois).show();
    } else {
      $(".subscription_"+mois).hide();
    }
    
    if (is_users_info_checked) {
      $subscriptions.removeAttr("disabled");
      $(".content.month_"+mois+" .user").show();
    } else {
      $subscriptions.attr("disabled","");
      $(".content.month_"+mois+" .user").hide();
    }
  });
  
  $(".do-showHideGlobal").change(function(){
    var is_subs_info_checked = $("#subscriptions_0").is(":checked");
    var is_users_info_checked = $("#users_0").is(":checked");
    
    if (!is_users_info_checked)
      $("#subscriptions_0").attr("disabled","disabled");
    else
      $("#subscriptions_0").removeAttr("disabled");
    
    $(".do-showHideInformation.users").each(function(index){
      var mois = $(this).attr("id").split("_")[1];
      
      $("#users_"+mois).attr("checked",is_users_info_checked);
      $("#subscriptions_"+mois).attr("checked",is_subs_info_checked);
      $("#subscriptions_"+mois).attr("disabled",!is_users_info_checked);
      
      if (is_subs_info_checked)
        $(".subscription_"+mois).show();
      else
        $(".subscription_"+mois).hide();
      
      if (is_users_info_checked)
        $(".content.month_"+mois+" .user").show();
      else
        $(".content.month_"+mois+" .user").hide();
    });
  });
  
  $(".do-showGlobal").click(function(){
    $(this).hide();
    $(this).parents(".actiongroup").children(".do-hideGlobal").show();
    $(this).parents(".header").next(".content").children(".month").children(".header").find(".actiongroup .do-hideThis").show();
    $(this).parents(".header").next(".content").children(".month").children(".header").find(".actiongroup .do-showThis").hide();
    $(this).parents(".header").next(".content").children(".month").children(".content").show();
  });
  
  $(".do-hideGlobal").click(function(){
    $(this).hide();
    $(this).parents(".actiongroup").children(".do-showGlobal").show();
    $(this).parents(".header").next(".content").children(".month").children(".header").find(".actiongroup .do-hideThis").hide();
    $(this).parents(".header").next(".content").children(".month").children(".header").find(".actiongroup .do-showThis").show();
    $(this).parents(".header").next(".content").children(".month").children(".content").hide();
  });
  
  $("a.do-showInvoice").click(function(){
    $invoiceDialog = $("#invoiceDialog");
    $invoiceDialog.find("h3").text($(this).attr("title"));
    $invoiceDialog.find("#invoice-show").attr("src",$(this).attr("href"));
    $invoiceDialog.modal();
    return false;
  });
  
});
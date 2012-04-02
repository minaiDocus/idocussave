$(document).ready(function(){
  $("#view_for").change(function(){
    id = $(this).val();
    
    $(".user").hide();
    $(".total").hide();
    
    if(id == 0) {
      $(".user").show();
      $(".total").show();
    } else {
      $(".user_"+id).show();
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
  
});
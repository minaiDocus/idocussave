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
  
  $(".do-showAll").click(function(){
    $(this).hide();
    $(this).parents(".actiongroup").children(".do-hideAll").show();
    $(this).parents(".header").next(".content").children(".user, .total").find(".do-hideThis").show();
    $(this).parents(".header").next(".content").children(".user, .total").find(".do-showThis").hide();
    $(this).parents(".header").next(".content").children(".user, .total").children(".content").show();
  });
  
  $(".do-hideAll").click(function(){
    $(this).hide();
    $(this).parents(".actiongroup").children(".do-showAll").show();
    $(this).parents(".header").next(".content").children(".user, .total").find(".do-hideThis").hide();
    $(this).parents(".header").next(".content").children(".user, .total").find(".do-showThis").show();
    $(this).parents(".header").next(".content").children(".user, .total").children(".content").hide();
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
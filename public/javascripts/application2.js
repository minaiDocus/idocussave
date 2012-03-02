$(document).ready(function(){
  $('.carousel').carousel();
   
  $('#connexion').modal({
    backdrop: true
  });
  $('#connexion').modal("hide");
  $(".modal-close").click(function(){
    $('#connexion').modal("hide");
  });
  
  $(".close").click(function(){
    $(this).parents("li").remove();
  });
  
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
          $(".alerts").html("<div class='alert alert-success'><a class='close' data-dismiss='alert'> × </a><span> Vos réglements seront maintenant débités de votre compte prépayé</span></div>"
          );
        } else if (data == "2") {
          $(".alerts").html("<div class='alert alert-success'><a class='close' data-dismiss='alert'> × </a><span> Vos réglements seront maintenant prélevés sur votre compte bancaire</span></div>"
          );
        } else if (data == "3") {
          $(".alerts").html("<div class='alert alert-info'><a class='close' data-dismiss='alert'> × </a><span> Vous n'avez pas encore configuré votre prélèvement</span></div>");
           
          $("#prlv").attr('checked', false);
          $("#pp").attr('checked', true);
        } else {
          $(".alerts").html("<div class='alert alert-error'><a class='close' data-dismiss='alert'> × </a><span> Une erreur s'est produite, veuillez réessayer plus tard</span></div>"
          );
        }
      }
    });
  });
  // Documents scripts
  
  $(".documents .action").hide();
  
  $(".documents .list li").hover(
    function(){
      $(this).children(".action").show();
    },
    function(){
      $(this).children(".action").hide();
    }
  );
  
  $(".show-pane").hide();
  
  $(".documents .hide-pane").click(function(){
    $(".documents .hide-pane").toggle();
    $(".documents .show-pane").toggle();
  });
  $(".documents .show-pane").click(function(){
    $(".documents .show-pane").toggle();
    $(".documents .hide-pane").toggle();
  });
  
  $(".selected .hide-pane").click(function(){
    $(".selected .hide-pane").toggle();
    $(".selected .show-pane").toggle();
  });
  $(".selected .show-pane").click(function(){
    $(".selected .show-pane").toggle();
    $(".selected .hide-pane").toggle();
  });
  
  $(".documents .hide-pane, .documents .show-pane, .selected .hide-pane, .selected .show-pane").click(function(){
    $(this).parents("div").children(".content-pane").toggle();
    if ($(this).parents(".pane").hasClass("span3")) {
      if ($(".pages").hasClass("span6")) {
        $(".pages").removeClass("span6");
        $(".pages").addClass("span8");
      } else if ($(".pages").hasClass("span8")) {
        $(".pages").removeClass("span8");
        $(".pages").addClass("span10");
      }
    } else {
      if ($(".pages").hasClass("span8")) {
        $(".pages").removeClass("span8");
        $(".pages").addClass("span6");
      } else if ($(".pages").hasClass("span10")) {
      $(".pages").removeClass("span10");
        $(".pages").addClass("span8");
      }
    }
    $(this).parents(".pane").toggleClass("span3").toggleClass("span1");
  });
  
  $(".documents .list .do-select").click(function(){
    $(this).parents("li").toggleClass("selected");
  });
  
  $("a.do-show").click(function(){
    link = $(this);
    var order_id = link.parents("li").attr("id");
    var url = "/account/documents/"+order_id;
    getDocument(url);
    return false;
  });
  
  $("a.do-archive").click(function(){
    link = $(this);
    var pack_id = link.parents("li").attr("id");
    $.ajax({
      url: "/account/documents/archive",
      data: hsh = {"pack_id":pack_id},
      dataType: "json",
      type: "POST",
      beforeSend: function() {
      },
      success: function(data){
        baseurl = window.location.pathname.split('/')[0];
        window.open(baseurl+""+data);
      }
    });
    return false;
  });
  
});

function getDocument(URL){
  $.ajax({
    url: URL,
    data: "",
    dataType: "html",
    type: "GET",
    beforeSend: function() {
    },
    success: function(data){
      $(".pages .list").html("");
      $(".pages .list").append(data);
    },
    error: function(data){
      alert("Une erreur est survenue");
    }
  });
  return false;
}

$('a.do-tooltip, information').tooltip({placement: 'top', trigger: 'hover'});
$('.do-popover').popover({placement: 'top'});
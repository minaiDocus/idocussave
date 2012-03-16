var ActionPerformCount = 0;

$(document).ajaxSend(function(e, xhr, options) {
  var token = $("meta[name='csrf-token']").attr("content");
  xhr.setRequestHeader("X-CSRF-Token", token);
});

function logBeforeAction(msg) {
  ActionPerformCount += 1;
  $(".feedback > .out").html(msg);
  $(".feedback").removeClass("inactive");
  $(".feedback").addClass("active");
}

function logAfterAction() {
  ActionPerformCount -= 1;
  if (ActionPerformCount <= 0) {
    ActionPerformCount = 0;
    $(".feedback > .out").html("Aucun traitement");
    $(".feedback").addClass("inactive");
    $(".feedback").removeClass("active");
  }
}

function remove_fields(link) {
  if(confirm("Êtes-vous sûr ?")){
    $(link).next("input[type=hidden]").val("true");
    $(link).parent().hide();
  }
}

function add_fields(link, association, content) {
  var count = parseInt($(link).next("input[name="+association+"_count]").val()) + 1;
  $(link).next("input[name="+association+"_count]").val(count);
  var regexp = new RegExp(association+"_attributes\]\[[0-9]*","g");
  var regexp2 = new RegExp(association+"_attributes_[0-9]*","g");
  var result = content.replace(regexp,association+"_attributes]["+count);
  result = result.replace(regexp2,association+"_attributes_"+count);
  $(link).before(result);
}

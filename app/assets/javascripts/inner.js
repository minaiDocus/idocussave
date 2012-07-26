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

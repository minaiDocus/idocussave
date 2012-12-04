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

Number.prototype.formatMoney = function(c, d, t){
    var n = this, c = isNaN(c = Math.abs(c)) ? 2 : c, d = d == undefined ? "," : d, t = t == undefined ? "." : t, s = n < 0 ? "-" : "", i = parseInt(n = Math.abs(+n || 0).toFixed(c)) + "", j = (j = i.length) > 3 ? j % 3 : 0;
    return s + (j ? i.substr(0, j) + t : "") + i.substr(j).replace(/(\d{3})(?=\d)/g, "$1" + t) + (c ? d + Math.abs(n - i).toFixed(c).slice(2) : "");
};
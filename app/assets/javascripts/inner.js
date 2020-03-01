//= require backbone_init

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

var notification_per_page = 5;
var notification_data = null;
function load_latest_notifications(load_more) {
    if (load_more || $('.dropdown-notifications.show').length == 0) {
        $.ajax({
            url: '/account/notifications/latest?per_page=' + (notification_per_page + (load_more ? 5 : 0)),
            success: function(data) {
                if ((load_more || $('.dropdown-notifications.show').length == 0) && notification_data != data) {
                    $('#notifications .items').html(data);
                    notification_data = data;
                    unread_notification_count = $('#unread_notification_count').data('count');
                    if (unread_notification_count > 0) {
                        $('#notifications .icon-bell').removeClass('notification-icon-disabled');
                        $('#notifications .icon-bell').addClass('notification-icon');
                    } else {
                        $('#notifications .icon-bell').removeClass('notification-icon');
                        $('#notifications .icon-bell').addClass('notification-icon-disabled');
                    }
                    $('#notifications .icon-bell').attr('data-count', unread_notification_count);
                    if (load_more)
                        notification_per_page += 5;
                }
            }
        });
    }
}

var notification_list = $('#notifications .items')
notification_list.scroll(function() {
    if ((notification_list.innerHeight() + notification_list.scrollTop()) >= notification_list[0].scrollHeight) {
        load_latest_notifications(true);
    }
});

load_latest_notifications(false);
setInterval(load_latest_notifications, 30000);

$('#news.modal').on('show.bs.modal', function (e) {
    $.ajax({
        url: '/account/news',
        beforeSend: function() {
            $('#news .modal-body').html("<img src='/assets/application/spinner_gray_alpha.gif' alt='chargement...' style='padding-top:184px;padding-left:399px;'/>");
        },
        success: function(data){
            $('#news .modal-body').html(data);
        }
    });
})
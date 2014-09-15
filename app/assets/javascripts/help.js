// Create the tooltips with params supplied
// style value can be 'red', 'blue', 'dark', 'light', 'green', 'jtools', 'plain', 'youtube', 'cluetip', 'tipsy', 'tipped', 'bootstrap'
function do_qtip(my, at, selectors, contents, styles) {
    // Loop through the my array
    for(var i = 0; i < my.length; i++) {
        $(selectors[i]).qtip({
            content: {
                title: {
                    text: $(contents[i]+" .title").html(),
                    button: true
                },
                text: $(contents[i]+" .text").html()
            },
            position: {
                my: my[i], // Use the corner...
                at: at[i] // ...and opposite corner
            },
            show: {
                event: false
            },
            hide: {
                event: false
            },
            style: {
                classes: 'ui-tooltip-shadow ui-tooltip-' + styles[i]
            }
        });
    }
}

var is_qtip_visible = false;

$(document).ready(function(){
    $(".toggle-qtip").click(function(){
        if ($(".qtip:visible").length == 0) {
            is_qtip_visible = false;
        }
        if (is_qtip_visible) {
            $(".qtip-target").qtip("hide");
            is_qtip_visible = false;
        } else {
            $(".qtip-target").qtip("show");
            is_qtip_visible = true;
        }
    });
});

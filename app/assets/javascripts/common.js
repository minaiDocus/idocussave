//= require jquery
//= require jquery_ujs
//= require jquery.ui.all
//= require bootstrap
//= require chart.min
//= require jquery.qtip.min
//= require help
//= require tmpl.min
//= require jquery.tokeninput.min
//= require jquery_nested_form
//= require file-uploader/load-image.min
//= require file-uploader/jquery.iframe-transport
//= require file-uploader/jquery.fileupload
//= require file-uploader/jquery.fileupload-ui
//= require file-uploader/application
//= require file-uploader/cors/jquery.xdr-transport
//= require shift_selectable
//= require searchable-option-list
//= require chosen.jquery
//= require bootstrap-filestyle.min
//= require bootstrap-datepicker/core
//
// French translation for bootstrap-datepicker
// Lola LAI KAM <lailol@directmada.com>
//
jQuery(function () {
  //For serializing Form to object
  $.fn.serializeObject = function() {
      var o = {};
      var a = this.serializeArray();
      $.each(a, function() {
          if (o[this.name]) {
            if (!o[this.name].push) {
                o[this.name] = [o[this.name]];
            }
            o[this.name].push(this.value || '');
          } else {
            o[this.name] = this.value || '';
          }
      });
      return o;
  };

  $.fn.datepicker.dates['fr'] = {
    days: ["Dimanche", "Lundi", "Mardi", "Mercredi", "Jeudi", "Vendredi", "Samedi", "Dimanche"],
    daysShort: ["Dim", "Lun", "Mar", "Mer", "Jeu", "Ven", "Sam", "Dim"],
    daysMin: ["Di", "Lu", "Ma", "Me", "Je", "Ve", "Sa", "Di"],
    months: ["Janvier", "Février", "Mars", "Avril", "Mai", "Juin", "Juillet", "Août", "Septembre", "Octobre", "Novembre", "Décembre"],
    monthsShort: ["Jan", "Fev", "Mar", "Avr", "Mai", "Jui", "Jul", "Aoû", "Sep", "Oct", "Nov", "Dec"]
  };

  $('.datepicker').datepicker({ format: 'yyyy-mm-dd', language: 'fr', orientation: 'bottom auto' });

  $("a[rel=popover]").popover();
  $(".tooltip").tooltip();
  $("a[rel=tooltip]").tooltip();

  $('input[type="checkbox"]').shiftSelectable();

  // Add a top padding when necessary

  $menu = $('.navbar-fixed-top');

  function dynamicTopPadding() {
    if ($menu.height() < 45) {
      $('.ad_dynamic_padding').css('padding-top', '0px');
      $('.dynamic_padding').css('padding-top', '60px');
    } else if ($menu.height() < 55) {
      $('.ad_dynamic_padding').css('padding-top', '0px');
      $('.dynamic_padding').css('padding-top', '0px');
    } else {
      $('.ad_dynamic_padding').css('padding-top', '40px');
      $('.dynamic_padding').css('padding-top', '100px');
    }
  }

  // Execute on load
  dynamicTopPadding();

  // Bind event listener
  $(window).resize(dynamicTopPadding);
});

function _require(script) {
    var src = ''
    $.ajax({
        url: script,
        dataType: "script",
        async: false,
        success: function (data) {
          src = data
        },
        error: function (e) {
          console.error(e)
          throw new Error("Could not load script " + script);
        }
    });
    return src;
}

//= require jquery
//= require jquery_ujs
//= require jquery.ui.all
//= require bootstrap
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
  $.fn.datepicker.dates['fr'] = {
    days: ["Dimanche", "Lundi", "Mardi", "Mercredi", "Jeudi", "Vendredi", "Samedi", "Dimanche"],
    daysShort: ["Dim", "Lun", "Mar", "Mer", "Jeu", "Ven", "Sam", "Dim"],
    daysMin: ["Di", "Lu", "Ma", "Me", "Je", "Ve", "Sa", "Di"],
    months: ["Janvier", "Février", "Mars", "Avril", "Mai", "Juin", "Juillet", "Août", "Septembre", "Octobre", "Novembre", "Décembre"],
    monthsShort: ["Jan", "Feb", "Mar", "Avr", "Mai", "Jui", "Jul", "Aoû", "Sep", "Oct", "Nov", "Dec"]
  };

  $('.datepicker').datepicker({ format: 'yyyy-mm-dd', language: 'fr', orientation: 'bottom auto' });

  $("a[rel=popover]").popover();
  $(".tooltip").tooltip();
  $("a[rel=tooltip]").tooltip();

  $('input[type="checkbox"]').shiftSelectable();
});

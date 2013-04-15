#//= require common.js
#//= require bootstrap-datepicker/core
#//
#// French translation for bootstrap-datepicker
#// Lola LAI KAM <lailol@directmada.com>
#//
jQuery ->
  $.fn.datepicker.dates['fr'] = {
    days: ["Dimanche", "Lundi", "Mardi", "Mercredi", "Jeudi", "Vendredi", "Samedi", "Dimanche"],
    daysShort: ["Dim", "Lun", "Mar", "Mer", "Jeu", "Ven", "Sam", "Dim"],
    daysMin: ["Di", "Lu", "Ma", "Me", "Je", "Ve", "Sa", "Di"],
    months: ["Janvier", "Février", "Mars", "Avril", "Mai", "Juin", "Juillet", "Août", "Septembre", "Octobre", "Novembre", "Décembre"],
    monthsShort: ["Jan", "Feb", "Mar", "Avr", "Mai", "Jui", "Jul", "Aoû", "Sep", "Oct", "Nov", "Dec"]
  }

jQuery ->
  $('.datepicker').datepicker format: 'yyyy-mm-dd', language: 'fr'
#//= require common.js
#//= require jquery_nested_form
#//= require fileuploader


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

  uploader_element = document.getElementById('file-uploader')
  if uploader_element
    uploader = new qq.FileUploader({
      # pass the dom node (ex. $(selector)[0] for jQuery users)
      element: uploader_element,
      # path to server-side upload script
      action: '#{ admin_cms_images_path }',
      onComplete: (id, fileName, responseJSON) ->
        if (responseJSON.success)
          # $("#avatar").attr("src", responseJSON.url);
          node = "<li><img src='"+responseJSON.url+"'/></li>"
          $('#cms_images').append(node)
          $$('.qq-upload-failed-text').first().update('Successfully Uploaded!')
        else
          $$('.qq-upload-failed-text').first().update('Hmm .. upload failed')
    })



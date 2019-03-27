//= require jquery
//= require jquery_ujs
//= require jquery-ui
//= require popper
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
//= require retractable
//
// French translation for bootstrap-datepicker
// Lola LAI KAM <lailol@directmada.com>
//

function custom_radio_buttons(){
  $('form .radio_buttons .control-section').each(function(e){
    $(this).find('.radio label').each(function(e){
      var text = $(this).text();
      if(text.length > 13) {
        $(this).attr('title', text);
        $(this).tooltip({placement: 'bottom', trigger: 'hover'});
      }
    });

    var label_parent = $(this).find('input[type="radio"]:checked').parent();
    label_parent.addClass('checked');
  });

  $('form .radio_buttons .control-section .radio label').unbind('click');
  $('form .radio_buttons .control-section .radio label').bind('click', function(e) {
    var section = $(this).parent().parent();
    section.find('label.checked').removeClass('checked');
    $(this).addClass('checked');
  });
}

function custom_checkbox_buttons(){
  $('form .check_boxes .control-section').each(function(e){
    $(this).find('.checkbox label').each(function(e){
      var text = $(this).text();
      if(text.length > 13){
        $(this).attr('title', text);
        $(this).tooltip({placement: 'bottom', trigger: 'hover'});
      }
    });

    var label_parent = $(this).find('input[type="checkbox"]:checked').parent();
    label_parent.addClass('checked');
  });

  $('form .check_boxes .control-section .checkbox label').unbind('click');
  $('form .check_boxes .control-section .checkbox label').bind('click', function(e) {
    if($(this).find('input[type="checkbox"]').is(':checked'))
      $(this).addClass('checked');
    else
      $(this).removeClass('checked');
  });
}

function custom_dynamic_height(){
  for(var i=1; i <= 5; i++) {
    var max_height = 0;
    if($('.height_groups.groups_'+i).length > 0){
      $('.height_groups.groups_'+i).each(function(e){
        if( max_height < $(this).innerHeight() ) max_height = $(this).innerHeight()
      });
      $('.height_groups.groups_'+i).attr('style', 'height:'+max_height+'px');
    }
  }
}

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

  //TODO: find a better way to remove form-control class from simple-form on sol-container object
  setTimeout(function(){ $('.sol-container').removeClass('form-control'); }, 1000);

  //workaround : bug Nav-tabs and Dropdowns menu Bootstrap
  $('.nav-tabs .dropdown').on('shown.bs.tab', 'a', function (e) {
      if(e.relatedTarget)
          $(e.relatedTarget).removeClass('active');

      $(e.delegateTarget).find('.dropdown-toggle:first-child').addClass('active');
      $('.nav-tabs .dropdown .dropdown-menu a').removeClass('active');
      $(e.currentTarget).addClass('active');
  });

  $("a[rel=popover]").popover();
  $(".tooltip").tooltip();
  $("a[rel=tooltip]").tooltip();

  $('input[type="checkbox"]').shiftSelectable();

  $('#as_user_view').click(function(e){
    e.preventDefault();

    var as_user_view_box = $('#as_user_view_box')
    if(as_user_view_box.is(':visible'))
      as_user_view_box.slideUp('fast');
    else
      as_user_view_box.slideDown('fast');
  });

  // Add a top padding when necessary

  // $menu = $('.navbar-fixed-top');

  // function dynamicTopPadding() {
  //   if ($menu.height() < 45) {
  //     $('.ad_dynamic_padding').css('padding-top', '0px');
  //     $('.dynamic_padding').css('padding-top', '60px');
  //   } else if ($menu.height() < 55) {
  //     $('.ad_dynamic_padding').css('padding-top', '0px');
  //     $('.dynamic_padding').css('padding-top', '0px');
  //   } else {
  //     $('.ad_dynamic_padding').css('padding-top', '40px');
  //     $('.dynamic_padding').css('padding-top', '100px');
  //   }
  // }

  // Execute on load
  // dynamicTopPadding();

  // Bind event listener
  // $(window).resize(dynamicTopPadding);

  //Custom Radio / Checkbox buttons
  custom_radio_buttons();
  custom_checkbox_buttons();

  //Custom dynamic height groups
  setTimeout(custom_dynamic_height, 1000);
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

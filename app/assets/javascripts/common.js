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
//= require jquery.livequery.min
//= require jquery_nested_form
//= require file-uploader/vendor/jquery.ui.widget
//= require file-uploader/fileupload-tpl
//= require file-uploader/fileupload-load-image
//= require file-uploader/fileupload-canvas-to-blob
//= require file-uploader/fileupload-blueimp-gallery
//= require file-uploader/jquery.iframe-transport
//= require file-uploader/jquery.fileupload
//= require file-uploader/jquery.fileupload-process
//= require file-uploader/jquery.fileupload-image
//= require file-uploader/jquery.fileupload-validate
//= require file-uploader/jquery.fileupload-ui
//= require file-uploader/cors/jquery.xdr-transport
//= require file-uploader/main
//= require shift_selectable
//= require searchable-option-list
//= require chosen.jquery
//= require bootstrap-filestyle.min
//= require bootstrap-datepicker/core
//= require retractable
//= require dynamic_hide_menu
//
// French translation for bootstrap-datepicker
// Lola LAI KAM <lailol@directmada.com>
//

function custom_radio_buttons(){
  $('form .radio_buttons .control-section').livequery(function(){
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
  });
}

function custom_checkbox_buttons(){
  $('form .check_boxes .control-section').livequery(function(){
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
  });
}

function custom_dynamic_height(){
  $('.height_groups').livequery(function(){
    for(var i=1; i <= 5; i++) {
      var min_height = 0;
      if($('.height_groups.groups_'+i).length > 0){
        $('.height_groups.groups_'+i).each(function(e){
          if( min_height < $(this).innerHeight() ) min_height = $(this).innerHeight()
        });
        $('.height_groups.groups_'+i).css('min-height', min_height+'px');
      }
    }
  });
}

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

function slideElement(elem_actor, elem_target, with_outer_div){
  //use mouseup action instead of click to avoid conflit
  $(elem_actor).bind('mouseup.slider', function(e){
    e.preventDefault();

    $(elem_actor).unbind('mouseup.slider'); //remove binder and reset it each time the function is triggered

    if(document.querySelector(elem_target).offsetHeight > 0)
    {
      $(elem_target).slideUp('fast');
      if(with_outer_div && $('#box_slide_element_outer')){
        $("#box_slide_element_outer").unbind('click.outerslider');
        $("#box_slide_element_outer").remove();
      }
    }
    else
    {
      $(elem_target).slideDown('fast');
      if(with_outer_div)
        $('body').append('<div id="box_slide_element_outer" style="top:0; left: 0; width: 100%; height: 100%; position: absolute; z-index: 10" />')
        $("#box_slide_element_outer").bind('click.outerslider', function(e){
          $("#box_slide_element_outer").unbind('click.outerslider');
          $(elem_target).slideUp('fast');
          $("#box_slide_element_outer").remove();
        });
    }

    slideElement(elem_actor, elem_target, with_outer_div); //remove binder and reset it each time the function is triggered
  });
}

function adjustIconColor(elem) {
  //add envents
  originalClick = $.fn.click
  $.fn.click = function(prop, value) {
    this.trigger('icon_click', [prop, value]);
    return originalClick.apply(this, arguments);
  }


  $('.oi-icon').livequery(function(){
    $('.oi-icon').each(function(e) {
      if(!$(this).hasClass('colored')) {
        var parent = $(this).parent();

        parent.unbind('mouseenter.iconEnter');
        parent.unbind('mouseleave.iconLeave');
        parent.unbind('click.iconClick');

        var handleChange = function(el, type) {
          var icon = el.find('.oi-icon:first');
          if(type == 'click')
            icon.addClass('clicked');

          if(!icon.hasClass('colored'))
          {
            if(type == 'in' || type == 'out')
            {
              icon.addClass('mouseentered');
              icon.css('fill', el.css('color'));
            }
          }
        }

        parent.bind('mouseenter.iconEnter', function() { handleChange($(this), 'in') });
        parent.bind('mouseleave.iconLeave', function() { handleChange($(this), 'out') });
        parent.bind('click.iconClick', function() { handleChange($(this), 'click') });

        $(this).css('fill', parent.css('color'));
      }
    });
  });

  $('.oi-icon.clicked').livequery(function(){
    $('.oi-icon.mouseentered, .oi-icon.last-clicked').each(function(){
      if(!$(this).hasClass('colored'))
      {
        $(this).removeClass('mouseentered');
        $(this).css('fill', $(this).parent().css('color'));
      }
      $(this).removeClass('last-clicked');
    });

    $('.oi-icon.clicked').each(function(){
      $(this).removeClass('clicked');
      $(this).addClass('last-clicked');
    })
  });
}

jQuery(function () {
  setTimeout(function(){ $('html').css('overflow', 'initial') }, 1200)

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

  $('#notifications.unread_all_onclick').click(function(e){
    $.ajax({
        url: "/account/notifications/unread_all_notifications",
        data: { unread:"all" },
        dataType: "json",
        type: "POST",
        success: function (data) {
          setTimeout(function(){ $('.notif-badge').hide(); }, 1000);
        }
    });
  });

  //animations
  slideElement('#as_user_view', '#as_user_view_box', false);
  slideElement('#notifications a.dropdown-itm', '#notifications .dropdown-menu', true);

  //adjust icons color
  adjustIconColor();
  //Custom Radio / Checkbox buttons
  custom_radio_buttons();
  custom_checkbox_buttons();
  //Custom dynamic height groups
  setTimeout(custom_dynamic_height, 1000);
});

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
//= require file-uploader/fileupload-tpl
//= require file-uploader/fileupload-load-image
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

function handlePaginationFilterSubmition(){
  $(".page-link-badge").click(function(e){
    e.preventDefault();
    var per_page = $(this).text().trim();
    if ($('.form-filter .per_page').length > 0)
    {
      $('.form-filter .per_page').val(per_page);
    }
    else
    {
      $('.form-filter').append('<input type="hidden" name="per_page" class="per_page" value="'+per_page+'">');
    }
    $('.form-filter').find('input[type="submit"]').click();
  });

  $('.pagination .page-item').click(function(e){
    e.preventDefault();
    var page = $(this).first().text().trim();
    if ($('.form-filter .page').length > 0)
    {
      $('.form-filter .page').val(page);
    }
    else
    {
      $('.form-filter').append('<input type="hidden" name="page" class="page" value="'+page+'">');
    }
    $('.form-filter').find('input[type="submit"]').click();
  });

  $('.form-filter').on('submit',function(e){
    if ($('.form-filter .per_page').length == 0)
    {
      var per_page = $(".page-link-badge.badge-info").first().text();
      $('.form-filter').append('<input type="hidden" name="per_page" class="per_page" value="'+per_page+'">');
    }
    if ($('.form-filter .page').length == 0 && $('.pagination').is(':visible'))
    {
      var page = $('.pagination .page-item.active').first().text().trim();
      $('.form-filter').append('<input type="hidden" name="page" class="page" value="'+page+'">');
    }
  });
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

  //Kip pagination state when filter is active
  if( $('.form-filter').is(":visible") && !$('.form-filter').hasClass('retriever_search') )
    handlePaginationFilterSubmition()

  //adjust icons color
  adjustIconColor();
  //Custom Radio / Checkbox buttons
  custom_radio_buttons();
  custom_checkbox_buttons();
  //Custom dynamic height groups
  setTimeout(custom_dynamic_height, 1000);
});

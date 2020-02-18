function generate_auto_scroll_for_div(link, direction){
  var to_scroll = link.parent('div').children('div').first();
  var leftPos   = to_scroll.scrollLeft();
  var left_or_right = direction == "right" ? leftPos + 200 : leftPos - 200

  to_scroll.animate({scrollLeft: left_or_right }, 800);
}

function show_hide_overflow(){  
  if (($('#navbarSupportedContent').width() - 991) < 220){      
      $('span[class^="auto-scroll-span"]').removeClass('hide')
      $('.auto-scroll-div').removeClass('mr-auto')
  }
  else{    
    $('span[class^="auto-scroll-span"]').addClass('hide')
    $('.auto-scroll-div').addClass('mr-auto')
  }
}

jQuery(function () {
  show_hide_overflow();

  $( window ).resize(function() {
    show_hide_overflow();
  });

  $('span[class^="auto-scroll-span"]').click(function(e){    
      var class_name = $(this).attr('class').split(' ')[0];
      var direction  = class_name.split('-')[3];
      generate_auto_scroll_for_div($(this),direction);
    });

  $('.auto-scroll-div .dropdown a').click(function(e){
    $('.auto-scroll-div .dropdown-menu').css({ 'position' : 'fixed !important', 'right' : 'auto', 'top' : 'auto', 'left' : $(this).offset().left });
  });
});
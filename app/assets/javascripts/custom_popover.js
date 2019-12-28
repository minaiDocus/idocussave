//Use a custom popover for big html data instead of bootstrap popover

function setPosition(elem) {
  var popover = elem.find('.my_custom_popover_wrapper');
  var marg_left = elem.outerWidth() || 15;
  var marg_top = -25;
  var marg_size = 70;

  popover.css('margin-top', marg_top + 'px');
  popover.css('margin-left', marg_left + 'px');

  var screen_height = $(window).innerHeight();
  var screen_width = $(window).innerWidth();

  var popover_height = popover.outerHeight();
  var popover_width = popover.outerWidth();

  if((popover_height + marg_size) > screen_height) {
    popover_height = screen_height - marg_size;
    popover.css('height', popover_height + 'px');
    popover.css('overflow-y', 'scroll');
  }

  if((popover_width + marg_size) > screen_width) {
    popover_width = screen_width - marg_size;
    popover.css('width', popover_width + 'px');
    popover.css('overflow-x', 'scroll');
  }

  var popover_left = popover.offset().left - $(window).scrollLeft();
  var popover_top = popover.offset().top - $(window).scrollTop();

  var diff_space = 0;

  var space_height = popover_top + popover_height;
  if(space_height >= screen_height) {
    diff_space = space_height - screen_height - (marg_top * 2);
    popover.css('margin-top', '-' + diff_space + 'px');
  }

  var space_width = popover_left + popover_width;
  if(space_width >= screen_width) {
    diff_space = popover_width - 1;
    popover.css('margin-left', '-' + diff_space + 'px');
  }
}

function showPopover(elem) {
  var data_content = elem.attr('data-content');

  hidePopover();
  elem.prepend('<div class="my_custom_popover_wrapper">' + data_content + '</div>');

  setPosition(elem);
}

function hidePopover() {
  $('body .my_custom_popover_wrapper').remove();
}


jQuery(function () {
  $.fn.custom_popover = function() {
    this.unbind('mouseenter.customPopover');
    this.bind('mouseenter.customPopover', function(e) {
      showPopover($(this)); 
    });

    this.unbind('mouseleave.customPopover');
    this.bind('mouseleave.customPopover', function(e) {
      hidePopover(); 
    });
  };
});
function setWidth(){
  var tableHead = $('table.table-detachable-head thead');
  var tableBody = $('table.table-detachable-head tbody');

  var tableWidth = $('table.table-detachable-head').innerWidth();

  tableHead.css('width', tableWidth+'px');
  var widthTH = [];

  tableHead.find('th').each(function(e){
    var thisWidth = $(this).innerWidth()
    widthTH.push(thisWidth);
    $(this).css('width', thisWidth+'px');
  });

  var first_tr = tableBody.find('tr:first-child');
  var counter = 0;

  first_tr.find('td').each(function(e){
    $(this).css('width', widthTH[counter]+'px');
    counter++;
  });
}

function removeWidth(){
  $('table.table-detachable-head thead').find('th').css('width', '');
  $('table.table-detachable-head tbody').find('tr:first-child > td').css('width', '');
}

function animationSlideDown(elem){
  if( elem.is('tbody') )
  {
    var interval_duration = 10;
    elem.find('tr').each(function(e) {
      $(this).addClass('to_show');
    });

    var animate = function() {
      var to_show = elem.find('tr.to_show:first');

      if( to_show.length > 0 ) {
        to_show.css('opacity', '1');
        to_show.removeClass('to_show');
        setTimeout(animate, interval_duration);
      }
    }
  }
  else
  {
    var interval_duration = 20;
    var current_height = elem.outerHeight();
    var step_height = current_height / 10;
    $(this).css('height', '0');

    var animate = function() {
      var next_height = elem.outerHeight() + step_height;

      if(next_height <= current_height) {
        elem.css('height', next_height+'px');
        step_height += 10;
        setTimeout(animate, interval_duration);
      } else {
        elem.css('height', current_height+'px');
      }
    }
  }

  elem.css('opacity', '1');
  setTimeout(animate, interval_duration);
}

function setFilterHeight(){
  var win_height = $(window).height();
  var footer_height = $('body footer').height();

  $('.retractable .retractable-filter .retractable-filter-content .card-body').each(function(e){
    var filter_top = $(this).offset().top;
    var max_height = win_height - footer_height - filter_top - 60; //marge of 50px (card-footer)
    var current_height = $(this).height();

    $(this).css('max-height', max_height+'px');
    if(current_height >= max_height)
      $(this).css('overflow-y', 'scroll');
  });
}

$(document).ready(function(){
  $('.retractable .retractable-filter .locker').on('click', function(e){
    e.preventDefault();
    if($('.retractable-filter .retractable-filter-content').is(':visible')){
      $('.retractable-filter .retractable-filter-content').slideUp('fast');
      $('.retractable-filter').addClass('close');
      $('.retractable.with-filter').attr('style', 'padding-right: 0px !important');
      $(this).attr('title', 'Afficher le filtre');
    }
    else
    {
      $('.retractable-filter .retractable-filter-content').slideDown('fast');
      $('.retractable.with-filter').removeAttr('style');
      $('.retractable-filter').removeClass('close');
      $(this).attr('title', 'Cacher le filtre');
    }
  });

  $('.retractable.slidedown').each(function(e) {
    animationSlideDown($(this));
  });

  setFilterHeight();

  $(window).scroll(function(e){
    if($('table.table-detachable-head').length > 0)
    {
      var tableTop = $('table.table-detachable-head').offset().top;
      var tableHead = $('table.table-detachable-head thead');
      var windowTop = $(window).scrollTop();

      if(windowTop > tableTop && !tableHead.hasClass('detached'))
      {
        setWidth();
        tableHead.addClass('detached');
        tableHead.slideDown(130);
      }
      else if( windowTop <= tableTop && tableHead.hasClass('detached'))
      {
        removeWidth();
        tableHead.removeClass('detached');
        tableHead.slideUp('fast', function(e){ tableHead.removeAttr('style'); });
      }
    }
  });
});
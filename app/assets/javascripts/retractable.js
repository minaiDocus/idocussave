function setWidth(){
  var tableHead = $('table.table-detachable-head thead');
  var tableBody = $('table.table-detachable-head tbody');

  var tableWidth = $('table.table-detachable-head').innerWidth();

  tableHead.attr('style', 'width:'+tableWidth+'px');
  var widthTH = [];

  tableHead.find('th').each(function(e){
    var thisWidth = $(this).innerWidth()
    widthTH.push(thisWidth);
    $(this).attr('style', 'width:'+thisWidth+'px');
  });

  tableBody.find('tr:first-child').each(function(e){
    var counter = 0;
    $(this).find('td').each(function(e){
      $(this).attr('style', 'width:'+widthTH[counter]+'px');
      counter++;
    });
  });
}

function removeWidth(){
  $('table.table-detachable-head thead').find('th').removeAttr('style');
  $('table.table-detachable-head tbody').find('tr:first-child > td').removeAttr('style');
}

$(document).ready(function(){
  $('.retractable .retractable-filter .locker').on('click', function(e){
    e.preventDefault();
    if($('.retractable-filter .retractable-filter-content').is(':visible')){
      $('.retractable-filter .retractable-filter-content').slideUp('fast');
      $('.retractable-filter').addClass('close');
      $('.retractable').removeClass('with-filter');
      $(this).attr('title', 'Afficher le filtre');
    }
    else
    {
      $('.retractable-filter .retractable-filter-content').slideDown('fast');
      $('.retractable').addClass('with-filter');
      $('.retractable-filter').removeClass('close');
      $(this).attr('title', 'Cacher le filtre');
    }
  });

  $(window).scroll(function(e){
    var tableTop = $('table.table-detachable-head').offset().top;
    var tableHead = $('table.table-detachable-head thead');
    var windowTop = $(window).scrollTop();

    if(windowTop > tableTop && !tableHead.hasClass('detached'))
    {
      setWidth();
      tableHead.addClass('detached');
      tableHead.slideDown('fast');
    }
    else if( windowTop <= tableTop && tableHead.hasClass('detached'))
    {
      removeWidth();
      tableHead.removeClass('detached');
      tableHead.slideUp('fast', function(e){ tableHead.removeAttr('style'); });
    }
  });
});
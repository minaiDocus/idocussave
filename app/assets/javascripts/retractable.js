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
});
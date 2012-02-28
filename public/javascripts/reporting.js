$(document).ready(function(){
  // Etat par mois
  /*$(".state_hb").hide();
  $(".state_month").hide();
  
  $(".state_sb").click(function(){
    var id1 = $(this).attr("id").split("_")[1];
    var id2 = $(this).attr("id").split("_")[2];
    
    $(".state_hb").hide();
    $(".state_sb").show();
    $(".state_month").hide();
    
    $("#sb_"+id1+"_"+id2).hide();
    $("#hb_"+id1+"_"+id2).show();
    
    $(".state_"+id1+"_"+id2).show();
  });  
  $(".state_hb").click(function(){
    var id1 = $(this).attr("id").split("_")[1];
    var id2 = $(this).attr("id").split("_")[2];
    
    $(".state_hb").hide();
    $(".state_sb").show();
    $(".state_month").hide();
    
    $("#hb_"+id1+"_"+id2).hide();
    $("#sb_"+id1+"_"+id2).show();
    
    $(".state_"+id1+"_"+id2).hide();
  });*/
  
  
  // all animation
  $(".do-showAll").hide();
  
  $(".do-hideAll").click(function () {
    $(".do-showAll").show();
    $(this).hide();
  });
  
  $(".do-showAll").click(function () {
    $(".do-hideAll").show();
    $(this).hide();
  });
  
  //All child animation
  $(".show_all_content").hide();
  
  $(".hide_all_content").click(function () {
    var id = $(this).attr("id").split("_")[1];
    $("#sac_"+id).show();
    $(this).hide();    
    $(".content_"+id).slideUp();

    $(".sc_"+id).show();
    $(".hc_"+id).hide();
  });
  
  $(".show_all_content").click(function () {
    var id = $(this).attr("id").split("_")[1];    
    $("#hac_"+id).show();
    $(this).hide();    
    $(".content_"+id).slideDown();
    
    $(".sc_"+id).hide();
    $(".hc_"+id).show();
  }); 
  
  // month animation  
  $(".show_month").hide();
  $(".hide_month").show();
  
  $(".show_month").click(function () {
    var id = $(this).attr("id").split("_")[1];
    $("#m_"+id+" .content").slideDown();
    $(this).hide();
    $("#h_"+id).show();
    
    $(".month_"+id+"_details").show();
  });
  
  $(".hide_month").click(function () {
    var id = $(this).attr("id").split("_")[1];
    $("#m_"+id+" .content").slideUp();
    $("#s_"+id).show();
    $(this).hide();
    
    $(".month_"+id+"_details").hide();
  });
    
  //child animation
  $(".s_c").hide();
  $(".show_child").click(function () {
    var id = $(this).attr("id").split("_")[1];
    var id2 = $(this).attr("id").split("_")[2];
    $(".child_"+id+"_"+id2).slideDown();
    $(this).hide();
    $("#hc_"+id+"_"+id2).show();
  });
  
  $(".hide_child").click(function () {
    var id = $(this).attr("id").split("_")[1];
    var id2 = $(this).attr("id").split("_")[2];
    $(".child_"+id+"_"+id2).slideUp();
    $("#sc_"+id+"_"+id2).show();
    $(this).hide();
  });   
  
  //total
  $(".s_c").click(function () {
    var id = $(this).attr("id").split("_")[1];
    
    $(".total_c"+id).slideDown();
    
    $(this).hide();
    $("#ht_"+id).show();
  });
  $(".h_c").click(function () {
    var id = $(this).attr("id").split("_")[1];
    
    $(".total_c"+id).slideUp();
    
    $("#st_"+id).show();
    $(this).hide();
  });
  
  $("a.do-showAll").click(function(){
    for(var i= 0; i < 12; i++) {
      $("#m_"+i+" .content").slideDown();
    }
    $(".show_month").hide();
    $(".hide_month").show();
    false
  });
  
  $("a.do-hideAll").click(function(){
    for(var i= 0; i < 12; i++) {
      $("#m_"+i+" .content").slideUp();
    }
    $(".hide_month").hide();
    $(".show_month").show();
    false
  });
  
  $("#view_for").change(function(){
    id = $(this).val();
    
    $(".child").hide();
    $(".statdoc").hide();
    
    if(id == 0) {
      $(".child").show();
      $(".statdoc").show();
    } else {
      $("."+id).show();
      $(".statdoc.c_"+id).show();
    }
    
    var total_ss_docs = 0;
    var total_feuilles = 0;
    var total_pages = 0;
    for(var i= 0; i < 12; i++)
    {
      //total ss-docs
      total = 0;
        $(".m_"+i+".pieces:visible").each(function(index) {
        total += parseInt($(this).text());
      });
      $(".m_"+i+".total-pieces").text(total);
      total_ss_docs += total;
      //total feuilles
      total = 0;
        $(".m_"+i+".sheets:visible").each(function(index) {
        total += parseInt($(this).text());
      });
      $(".m_"+i+".total-sheets").text(total);
      total_feuilles += total;
      //total pages
      total = 0;
        $(".m_"+i+".pages:visible").each(function(index) {
        total += parseInt($(this).text());
      });
      $(".m_"+i+".total-pages").text(total);
      total_pages += total;
    }
    $(".total-pieces.global").text(total_ss_docs);
    $(".total-sheets.global").text(total_feuilles);
    $(".total-pages.global").text(total_pages);
  });
  
});
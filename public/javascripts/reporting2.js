function render_data(refs){
  if (refs != "") {
    var _refs = refs.split("_");
    var user_id = _refs[1];
    var period_id = _refs[2];
    var month = _refs[3];
    var duration = _refs[4];
    
    var $periodModal = $("#periodModal");
    
    var $prev = $(".user_id_" + user_id + ".n_" + (month - duration));
    var prev_id = "";
    if ($prev.length > 0) {
      var _prev_refs = $prev.parent("a.do-show").attr("id").split("_");
      var prev_period_id = _prev_refs[2];
      var prev_month = _prev_refs[3];
      var prev_duration = _prev_refs[4];
      var prev_id = "link_" + user_id + "_" + prev_period_id + "_" + prev_month + "_" + prev_duration;
    }
    
    var $next = $(".user_id_" + user_id + ".n_" + (parseInt(month) + parseInt(duration)));
    var next_id = "";
    if ($next.length > 0) {
      var _next_refs = $next.parent("a.do-show").attr("id").split("_");
      var next_period_id = _next_refs[2];
      var next_month = _next_refs[3];
      var next_duration = _next_refs[4];
      var next_id = "link_" + user_id + "_" + next_period_id + "_" + next_month + "_" + next_duration;
    }
    
    $periodModal.find(".prev").attr("id",prev_id);
    $periodModal.find(".next").attr("id",next_id);
    
    $.ajax({
      url: "/account/scan/periods/" + period_id,
      data: "",
      dataType: "json",
      type: "GET",
      beforeSend: function() {
      },
      success: function(data){
        $periodModal.find(".modal-body").html(tmpl("tmpl-period",data));
        $periodModal.modal();
      }
    });
  }
}

$(document).ready(function(){
  $("a.do-show").click(function(){
    render_data($(this).attr("id"));
    false;
  });
});

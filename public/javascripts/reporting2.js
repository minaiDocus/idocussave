var mois = ["Janvier","Février","Mars","Avril","Mai","Juin","Juillet","Août","Septembre","Octobre","Novembre","Décembre"];
var year = $("#year").val();
$(".period .value span").addClass("hide");
$(".period .value .value_0").removeClass("hide");

function render_data(refs){
  if (refs != "") {
    var _refs = refs.split("_");
    var user_id = _refs[1];
    var period_id = _refs[2];
    var month = parseInt(_refs[3]);
    var duration = parseInt(_refs[4]);
    
    var $periodModal = $("#periodModal");
    
    var $prev = $(".user_id_" + user_id + ".n_" + (month - duration));
    var prev_id = "";
    if ($prev.length > 0) {
      var _prev_refs = $prev.parent("a.do-show").attr("id").split("_");
      var prev_period_id = _prev_refs[2];
      var prev_month = _prev_refs[3];
      var prev_duration = _prev_refs[4];
      var prev_id = "link_" + user_id + "_" + prev_period_id + "_" + prev_month + "_" + prev_duration;
      $periodModal.find(".prev").removeAttr("disabled");
    } else {
      $periodModal.find(".prev").attr("disabled","disabled");
    }
    $periodModal.find(".prev").attr("id",prev_id);
    
    var $next = $(".user_id_" + user_id + ".n_" + (month + duration));
    var next_id = "";
    if ($next.length > 0) {
      var _next_refs = $next.parent("a.do-show").attr("id").split("_");
      var next_period_id = _next_refs[2];
      var next_month = _next_refs[3];
      var next_duration = _next_refs[4];
      var next_id = "link_" + user_id + "_" + next_period_id + "_" + next_month + "_" + next_duration;
      $periodModal.find(".next").removeAttr("disabled");
    } else {
      $periodModal.find(".next").attr("disabled","disabled");
    }
    
    $periodModal.find(".next").attr("id",next_id);
    
    if (duration == 1) {
      $("#periodModal .modal-header h3").text(mois[month - 1] + " " + year);
    } else if (duration == 3) {
      if (month == 1) {
        $("#periodModal .modal-header h3").html("1<sup>er</sup> trimestre " + year);
      } else if (month == 4) {
        $("#periodModal .modal-header h3").html("2<sup>nd</sup> trimestre " + year);
      } else if (month == 7) {
        $("#periodModal .modal-header h3").html("3<sup>éme</sup> trimestre " + year);
      } else if (month == 10) {
        $("#periodModal .modal-header h3").html("4<sup>éme</sup> trimestre " + year);
      }
    }
    
    $.ajax({
      url: "/account/scan/periods/" + period_id,
      data: "",
      dataType: "json",
      type: "GET",
      beforeSend: function(){
        $("#periodModal .modal-body").html("<img src='/images/application/spinner_gray_alpha.gif' alt='chargement...' style='position:relative;top:142px;left:468px;'/>");
      },
      success: function(data){
        $periodModal.find(".modal-body").html(tmpl("tmpl-period",data));
      }
    });
    
    $periodModal.modal();
  }
}

$(document).ready(function(){
  $("a.do-show").click(function(){
    render_data($(this).attr("id"));
    false;
  });
  
  $("#filter").submit(function(){
    var user_id = $("#user_filter").val();
    if (user_id == "0") {
      $(".user").removeClass("hide");
    } else {
      $(".user").addClass("hide");
      $("#user_"+user_id).removeClass("hide");
    }
    
    var class_tags = ""
    
    var $account_book_filter = $("#account_book_filter");
    var $year_filter = $("#year_filter");
    var $month_filter = $("#month_filter");
    if ($account_book_filter.val().length > 0) {
      class_tags += ".b_" + $account_book_filter.val();
    }
    if ($year_filter.val().length > 0) {
      class_tags += ".y_" + parseInt($year_filter.val());
    }
    if ($month_filter.val().length > 0) {
      class_tags += ".m_" + parseInt($month_filter.val());
    }
    
    $(".period").removeClass("selected");
    
    $results = $(".period:visible "+class_tags)
    $("#filter_results").text($results.length + " résultat(s)");
    $results.each(function(index){
      $(this).parents(".period").addClass("selected");
    });
    
    if ($account_book_filter.val().length == 0 && $year_filter.val().length == 0 && $month_filter.val().length == 0) {
      $(".period:visible").addClass("selected");
    }
    return false;
  });
  
  $("#value_filter").change(function(){
    var val = $(this).val();
    $(".period .value span").addClass("hide");
    $(".period .value .value_"+val).removeClass("hide");
  });
});

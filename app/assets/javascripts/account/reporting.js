var mois = ["Janvier","Février","Mars","Avril","Mai","Juin","Juillet","Août","Septembre","Octobre","Novembre","Décembre"];
var year = $("#year").val();

$(".period .value span").addClass("hide");
$(".period .value .value_0").removeClass("hide");

var period_x = 1;
var period_y = 1;

function go_left(){
 return navigate(-1,0,true);
}

function left(){
  return navigate(-1,0,false);
}

function go_right(){
 return navigate(1,0,true);
}

function right(){
  return navigate(1,0,false);
}

function go_up(){
 return navigate(0,-1,true);
}

function up(){
  return navigate(0,-1,false);
}

function go_down(){
 return navigate(0,1,true);
}

function down(){
  return navigate(0,1,false);
}

function refresh_navigation_button(){
  if(left() != null){
    $('a.left').removeClass('disabled');
  }else{
    $('a.left').addClass('disabled');
  }
  if(right() != null){
    $('a.right').removeClass('disabled');
  }else{
    $('a.right').addClass('disabled');
  }
  if(up() != null){
    $('a.up').removeClass('disabled');
  }else{
    $('a.up').addClass('disabled');
  }
  if(down() != null){
    $('a.down').removeClass('disabled');
  }else{
    $('a.down').addClass('disabled');
  }
}

function navigate(x,y,move){
  if(!(x == 0 && y == 0)){
    if(((period_x+x) > 0 && (period_x+x) < 13) && ((period_y+y) > 0 && (period_y+y) <= max_period_y)){
      current_period = $('.pos_'+period_y+'_'+period_x)[0];
      period = $('.pos_'+(period_y+y)+'_'+(period_x+x))[0];
      if(period != null && period != current_period){
        if(move == true){
          period_x += x;
          period_y += y;
        }
        return period;
      }else{
        new_x = x;
        new_y = y;
        if(x > 0){
          new_x++;
        }else if(x < 0){
          new_x--;
        }
        if(y > 0){
          new_y++;
        }else if(y < 0){
          new_y--;
        }
        return navigate(new_x,new_y,move);
      }
    }else{
      return null;
    }
  }else{
    return null;
  }
}

function render_data(period){
  if(period != null){
    var $period = $(period);
    var period_id = $period.attr('id');
    var user_id = $period.attr('user_id');
    var month = parseInt($period.attr('month'));
    var duration = parseInt($period.attr('duration'));

    var $periodModal = $("#periodModal");

    $("#periodModal .modal-header .user h4").text($("#user_"+user_id).find('td:first').text());

    if (duration == 1) {
      $("#periodModal .modal-header .period h3").text(mois[month - 1] + " " + year);
    } else if (duration == 3) {
      if (month == 1) {
        $("#periodModal .modal-header h3").html("1<sup>er</sup> trimestre " + year);
      } else if (month == 4) {
        $("#periodModal .modal-header h3").html("2<sup>éme</sup> trimestre " + year);
      } else if (month == 7) {
        $("#periodModal .modal-header h3").html("3<sup>éme</sup> trimestre " + year);
      } else if (month == 10) {
        $("#periodModal .modal-header h3").html("4<sup>éme</sup> trimestre " + year);
      }
    } else if (duration == 12) {
      $("#periodModal .modal-header h3").text(year);
    }

    $.ajax({
      url: "/account/periods/" + period_id,
      data: "",
      dataType: "json",
      type: "GET",
      beforeSend: function(){
        $("#periodModal .modal-body").html("<img src='/assets/application/spinner_gray_alpha.gif' alt='chargement...' style='position:relative;left:468px;'/>");
      },
      success: function(data){
        $periodModal.find(".modal-body").html(tmpl("tmpl-period",data));
        var account_book_filter = $("#account_book_filter").val();
        var year_filter = parseInt($("#year_filter").val());
        var month_filter = parseInt($("#month_filter").val());
        var quarter_filter = parseInt($("#quarter_filter").val());
        $("#periodModal .name").each(function(index){
          var is_ok = true;
          var name = $(this).text().trim().split(" ");
          var account_book_value = name[1];
          var year_value = parseInt(name[2].substr(0,4));
          var month_value = undefined;
          var quarter_value = undefined;
          if(name[2][4] == 'T') {
            var quarter_value = parseInt(name[2].substr(5,1));
          } else if (name[2][4] != undefined) {
            var month_value = parseInt(name[2].substr(4,2));
          }
          if(account_book_filter.length > 0 && account_book_filter != account_book_value)
            is_ok = false;
          if(year_filter && year_filter != year_value)
            is_ok = false;
          if(month_filter && month_filter != month_value)
            is_ok = false;
          if(quarter_filter && quarter_filter != quarter_value)
            is_ok = false;
          if(is_ok && (account_book_filter.length > 0 || year_filter || month_filter)){
            $(this).parents("tr").addClass("selected");
          }
        });

        $(".do-popover").popover({placement: 'right'});
        initDoShowInvoice();
      }
    });
    refresh_navigation_button();
    $periodModal.modal();
  }
}

function apply_filter(){
  var user_id = $("#user_filter").val();
  if (user_id == "0") {
    $(".user").removeClass("hide");
    $("#total").removeClass("hide");
  } else {
    $(".user").addClass("hide");
    $("#total").addClass("hide");
    $("#user_"+user_id).removeClass("hide");
  }

  var class_tags = ""

  var $account_book_filter = $("#account_book_filter");
  var $year_filter = $("#year_filter");
  var $month_filter = $("#month_filter");
  var $quarter_filter = $("#quarter_filter");
  if ($account_book_filter.val().length > 0) {
    class_tags += ".b_" + $account_book_filter.val();
  }
  if ($year_filter.val().length > 0) {
    class_tags += ".y_" + parseInt($year_filter.val());
  }
  if ($month_filter.val().length > 0) {
    class_tags += ".m_" + parseInt($month_filter.val());
  }
  if ($quarter_filter.val().length > 0) {
    class_tags += ".t_" + parseInt($quarter_filter.val());
  }

  $(".period").removeClass("selected");
  if (class_tags.length > 0) {
    $results = $(".period:visible "+class_tags);
    $results.each(function(index){
      $(this).parents(".period").addClass("selected");
    });
    $("#filter_results").text($results.length + " résultat(s)");
  } else {
    $("#filter_results").text("");
  }
}

function initDoShowInvoice(){
  $link = $("a.do-showInvoice");
  $link.unbind('click');
  $link.bind('click',function(e){
    $invoiceDialog = $("#invoiceDialog");
    $invoiceDialog.find("h3").text($(this).attr("title"));
    $invoiceDialog.find("#invoice-show").attr("src",$(this).attr("href"));
    $invoiceDialog.modal();
    e.preventDefault();
  });
}

function showPeriodsInfo(value){
  $(".value span").addClass("hide");
  $(".value .value_"+value).removeClass("hide");
}

$(document).ready(function(){
  max_period_y = $('.user').length;

  $('.custom_popover').custom_popover();
  initDoShowInvoice();

  $("a.do-show").click(function(){
    var $period = $(this).find('.period');
    period_x = parseInt($period.attr('month'));
    period_y = parseInt($period.attr('row'));
    render_data($period);
    return false;
  });

  $("span.badge").tooltip();

  $("#reset_filter").click(function(){
    $("#user_filter").val("0");
    $("#account_book_filter").val("");
    $("#year_filter").val("");
    $("#month_filter").val("");
    $("#quarter_filter").val("");
    apply_filter();
    return false;
  });

  $("#filter").submit(function(){
    apply_filter();
    return false;
  });

  showPeriodsInfo($("#value_filter").val());

  $("#value_filter").change(function(){
    showPeriodsInfo($(this).val());
  });

  $('a.up').click(function(){
    render_data(go_up());
    return false;
  });

  $('a.down').click(function(){
    render_data(go_down());
    return false;
  });

  $('a.left').click(function(){
    render_data(go_left());
    return false;
  });

  $('a.right').click(function(){
    render_data(go_right());
    return false;
  });

  $('select#user_filter').chosen({
    search_contains: true,
    no_results_text: 'Aucun résultat correspondant à'
  })
});

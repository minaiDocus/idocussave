var initEventOnPiecesRefresh = function(){
  $("a.do-showPage").unbind('click');
  $("a.do-showPage").bind('click',function() {
    showPage($(this));
    return false;
  });

  $("a.do-selectPage").unbind("click");
  $("a.do-selectPage").bind("click",function() {
    selectPage($(this));
    return false;
  });

  $(".do-selectAllPages").unbind('click');
  $(".do-selectAllPages").click(function(e){
    e.preventDefault();
    $("#show_pages li.pages").each(function(index,li){
      if (!$(li).hasClass("selected")) {
        $(li).addClass("selected");
        addPage($(li));
      }
    });
  });

  $(".do-unselectAllPages").unbind('click');
  $(".do-unselectAllPages").click(function(e){
    e.preventDefault();
    $("#show_pages li.pages").removeClass("selected");
    $("#show_pages li.pages").each(function(index,li){
      removePage($(li));
    });
  });

  $("a.do-selectSinglePage").unbind('click');
  $("a.do-selectSinglePage").click(function(e){
    e.preventDefault();
    var id = "#document_" + $(".showPage").attr("id");
    var li = $(id);
    li.addClass("selected");
    addPage(li);
  });

  $("a.do-unselectSinglePage").unbind('click');
  $("a.do-unselectSinglePage").click(function(e){
    e.preventDefault();
    var id = "#document_" + $(".showPage").attr("id");
    var li = $(id);
    li.removeClass("selected");
    removePage(li);
  });

  $("#panel2 a.do-nextPage").unbind('click');
  $("#panel2 a.do-nextPage").click(function(e){
    e.preventDefault();
    var id = $("#panel2 .showPage").attr("id");
    var li = $("#document_"+id);
    var link = li.next().children(".do-showPage");
    if (link.length > 0)
      showPage(link);
  });

  $("#panel2 a.do-prevPage").unbind('click');
  $("#panel2 a.do-prevPage").click(function(e){
    e.preventDefault();
    var id = $("#panel2 .showPage").attr("id");
    var li = $("#document_"+id);
    var link = li.prev().children(".do-showPage")
    if (link.length > 0)
      showPage(link);
  });

  $("#panel3 a.do-nextPage").unbind('click');
  $("#panel3 a.do-nextPage").click(function(e){
    e.preventDefault();
    var id = $("#panel3 .showPage").attr("id");
    var li = $("#document_"+id);
    var link = li.next().children(".do-showPage");
    if (link.length > 0)
      showPage(link);
  });

  $("#panel3 a.do-prevPage").unbind('click');
  $("#panel3 a.do-prevPage").click(function(e){
    e.preventDefault();
    var id = $("#panel3 .showPage").attr("id");
    var li = $("#document_"+id);
    var link = li.prev().children(".do-showPage")
    if (link.length > 0)
      showPage(link);
  });

  $(".backToPanel1").unbind('click');
  $(".backToPanel1").click(function(){
    $("#panel2").hide();
    $("#panel3").hide();
    $("#panel1").show();

    $(".actiongroup.group1").show();
    $(".actiongroup.group2").hide();
    return false;
  });

  $(".do-goToPreseizure").unbind('click');
  $(".do-goToPreseizure").click(function(e){
    e.preventDefault();
    var piece_id = $(this).attr('data-id');
    if(piece_id > 0)
    {
      window.currentView = 'preseizures';
      getPreseizures(window.currentLink, 1, piece_id, false);
    }
  });

  $('#do-showAllPieces').unbind('click');
  $('#do-showAllPieces').click(function(e){
    e.preventDefault();
    showPieces(window.currentLink, 1);
  });
}

var initEventOnPiecesSelection = function(){
  $("a.do-removePageFromSelection").unbind("click");
  $("a.do-removePageFromSelection").bind("click",function() {
    removePageFromSelection($(this));
    return false;
  });


  $("a.removeAllSelection").unbind('click');
  $("a.removeAllSelection").click(function(e) {
    e.preventDefault();
    synchroniseRemovedSelection();
    $("#selectionlist .content ul").html("");
    toogleSelectionBox();
    $.ajax({
      url: '/account/compositions/reset',
      data: { _method: 'DELETE' },
      dataType: "json",
      type: "POST",
      beforeSend: function() {
        logBeforeAction("Traitement en cours");
      },
      success: function(data){
        logAfterAction();
      },
      error: function(data){
        logAfterAction();
        $(".alerts").html("<div class='row'><div class='col-md-12 alert alert-danger'><a class='close' data-dismiss='alert'> × </a><span> Une erreur est survenue et l'administrateur a été informé.</span></div></div>");
      }
    });
  });
}

$('#file_account_book_type').val($('#h_file_account_book_type').val());
$('#file_prev_period_offset').val($('#h_file_prev_period_offset').val());

var lock_or_unlock_file_upload_params_interval = null;
$('#uploadDialog').on('show.bs.modal', function() {
  window.analytic_target_form = '#fileupload'
  lock_or_unlock_file_upload_params_interval = setInterval(lock_or_unlock_file_upload_params, 500);
});

$('#uploadDialog').on('shown.bs.modal', function() {
  var ready = false

  if( $('#h_file_code').val() != '' && ( $('#fileupload').data('params') == 'undefined' || jQuery.isEmptyObject($('#fileupload').data('params')) ) ) {
    ready = true
  } else {
    $('#h_file_code').chosen({
      search_contains: true,
      allow_single_deselect: true,
      no_results_text: 'Aucun résultat correspondant à'
    })
  }

  if ( ready || ( ($('#h_file_code').val() != '' && $('#h_file_code').val() != undefined ) && ($('#h_file_account_book_type').val() != '' && $('#h_file_account_book_type').val() != undefined) ) )
    window.setAnalytics($('#h_file_code').val(), $('#h_file_account_book_type').val(), 'journal', true);
});

$('#uploadDialog').on('hide', function() {
  window.analytic_target_form = null
  clearInterval(lock_or_unlock_file_upload_params_interval);
});

$('#comptaAnalysisEdition').on('show.bs.modal', function() {
  if(window.analytic_target_form != '#fileupload')
  {
    $('#analysis_validate').removeClass('hide');
    var document_ids = $.map($("#selectionlist > .content > ul > li"), function(li){ return li.id.split("_")[1] });
    window.setAnalytics(window.user_code, document_ids, 'piece', true);
  }
  else
  {
    $('#analysis_validate').addClass('hide');
  }
});

$('#comptaAnalysisEdition').on('hide', function() {
  $("#comptaAnalysisEdition .length_alert").html('');

  if(window.analytic_target_form == '#fileupload'){
    $("#uploadDialog .analytic_resume_box").html(window.getAnalyticsResume());
    $('#analytic_user_fields .with_default_analysis').hide();
  }
});

$('#analysis_validate').on('click', function(){
  var document_ids = $.map($("#selectionlist > .content > ul > li"), function(li){ return li.id.split("_")[1] });
  if (document_ids.length <= 0)
  {
    $("#comptaAnalysisEdition .length_alert").html("<div class='alert alert-danger'><a class='close' data-dismiss='alert'> × </a><span>Veuillez sélectionner au moins un document.</span></div>");
  }
  else 
  {
    var data = $('#comptaAnalysisEdition #compta_analytic_form_modal').serialize()
    data += '&document_ids='+document_ids
    $.ajax({
      url: "/account/documents/compta_analytics/update_multiple",
      data: data,
      dataType: "json",
      type: "POST",
      beforeSend: function() {
        logBeforeAction("Traitement en cours");
        $('#comptaAnalysisEdition .analytic_validation_loading').removeClass('hide');
      },
      success: function(data){
        logAfterAction();
        $('#comptaAnalysisEdition .analytic_validation_loading').addClass('hide');

        full_message = ""

        if(data.sending_message.length > 0){
          full_message += "<div class='alert alert-success'><a class='close' data-dismiss='alert'> × </a><span>" + data.sending_message + "</span></div>"
        }

        if(data.error_message.length > 0) {
          full_message += "<div class='alert alert-danger'><a class='close' data-dismiss='alert'> × </a><span>" + data.error_message + "</span></div>";
        } else {
          setTimeout(function(){ $('#comptaAnalysisEdition').modal('hide') }, 2000)
        }

        $("#comptaAnalysisEdition .length_alert").html(full_message)
      },
      error: function(data){
        logAfterAction();
        $('#comptaAnalysisEdition .analytic_validation_loading').addClass('hide');
        $("#comptaAnalysisEdition .length_alert").html("<div class='alert alert-danger'><a class='close' data-dismiss='alert'> × </a><span> Une erreur est survenue et l'administrateur a été prévenu.</span></div>");
      }
    });
  }
});

$("#compositionDialog").on("hidden.bs.modal",function() {
  $("#compositionDialog .length_alert").html("");
  $("#compositionDialog .names_alert").html("");
  $("#composition_name").val("");
});

$("#composition_name").change(function() {
  $("#compositionDialog .names_alert").html("");
});

$("#compositionButton").click(function() {
  var document_ids = $.map($("#selectionlist > .content > ul > li"), function(li){ return li.id.split("_")[1] });
  var $composition_name = $("#composition_name");

  if (document_ids.length <= 0)
    $("#compositionDialog .length_alert").html("<div class='alert alert-danger'><a class='close' data-dismiss='alert'> × </a><span>Veuillez sélectionner au moins un document.</span></div>");
  if ($composition_name.val().length <= 0)
    $("#compositionDialog .names_alert").html("<div class='alert alert-danger'><a class='close' data-dismiss='alert'> × </a><span>Veuillez indiquer le nom de la composition.</span></div>");

  if (document_ids.length > 0 && $composition_name.val().length > 0) {
    var hsh = {"composition[document_ids]": document_ids, "composition[name]": $composition_name.val()};
    $.ajax({
      url: "/account/compositions",
      data: hsh,
      dataType: "json",
      type: "POST",
      beforeSend: function() {

      },
      success: function(data){

        baseurl = window.location.pathname.split('/')[0];
        window.open(baseurl+""+data);
      }
    });
  }
  return false;
});
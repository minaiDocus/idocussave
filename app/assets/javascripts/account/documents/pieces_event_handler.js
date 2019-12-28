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
        $(this).find('.do-selectPage-check-icon').addClass('hide');
        $(this).find('.do-selectPage-ban-icon').removeClass('hide');
        addPage($(li));        
      }
    });

    if($("#show_pages li.pages.selected").length > 1)
      $('.composer').show();

    $(".compta_analysis_edition, .delete_piece_composition").show();
    $(".delete_piece_composition, .piece_tag, .compta_analysis_edition, .composer").addClass('border_piece_action');
  });

  $(".do-unselectAllPages").unbind('click');
  $(".do-unselectAllPages").click(function(e){
    e.preventDefault();
    $("#show_pages li.pages").removeClass("selected");
    $("#show_pages li.pages").each(function(index,li){
      $(this).find('.do-selectPage-check-icon').removeClass('hide');
      $(this).find('.do-selectPage-ban-icon').addClass('hide');
      removePage($(li));
    });
    window.preseizuresSelected = [];
    $(".compta_analysis_edition, .composer, .delete_piece_composition").hide();
    $(".delete_piece_composition, .piece_tag, .composer, .do-deliverAllPreseizure").removeClass('border_piece_action');
    $(".do-exportSelectedPreseizures, .do-deliverAllPreseizure, .tip_edit_multiple, .do-exportSelectedPreseizures").removeClass('border_action_preseizure');
    $(".content_preseizure, .tab").removeClass('preseizure_selected active');
    $('input[type="checkbox"').prop('checked',false);
    $(".tip_edit_multiple").addClass('hide');
  });  

  $("a.do-nextPage").unbind('click');
  $("a.do-nextPage").click(function(e){
    e.preventDefault();
    e.stopPropagation();
    var id = $("#PdfViewerDialog .showPage").val();
    var li = $("#document_"+id);
    var link = li.next().children(".do-showPage");
    if (link.length > 0)
      showPage(link,"next");
  });

  $("a.do-prevPage").unbind('click');
  $("a.do-prevPage").click(function(e){
    e.preventDefault();
    e.stopPropagation();
    var id = $("#PdfViewerDialog .showPage").val();
    var li = $("#document_"+id);
    var link = li.prev().children(".do-showPage")
    if (link.length > 0)
      showPage(link,"previous");
  }); 

  $("a.piece").unbind('click');
  $("a.piece").bind('click',function(e) {
    deletePiece($(this).attr('id'));
    return false;
  });

  $(".delete_piece_composition").unbind('click');
  $(".delete_piece_composition").bind('click',function(e) {
    deletePieceComposition();
    return false;
  });

  $(".check_modif_preseizure input").unbind('click');
  $(".check_modif_preseizure input").click(function(e) {
    var _id = $(this).attr('id');
    
    if ($("#div"+_id).hasClass("preseizure_selected active"))
    {     
      $("#span"+_id).removeClass("preseizure_selected");
      $("#div"+_id).removeClass("preseizure_selected active");
    }
    else 
    {      
      $("#span"+_id).addClass("preseizure_selected");
      $("#div"+_id).addClass("preseizure_selected active");
    }           

    handlePreseizureSelection(_id);
    togglePreseizureAction();
  });

  $(".custom_popover").unbind('click');
  $(".custom_popover").click(function(e) {
    var data_content = $(this).attr('data-content');

    $("#PdfViewerDialog").modal('show');
    $("#PdfViewerDialog .modal-body .view-content").html(data_content);    
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
    var document_ids = $.map($("#lists_pieces > #lists_pieces_content > ul#pages > li.selected"), function(li){ return li.id.split("_")[1] });
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
  var document_ids = [];
  $("#lists_pieces > #lists_pieces_content > ul > li.selected").each(function(li){ 
      document_ids.push($(this).attr('id').split("_")[1]); 
  });

  if (document_ids.length <= 0)
  {
    $("#comptaAnalysisEdition .length_alert").html("<div class='alert alert-danger'><a class='close' data-dismiss='alert'> × </a><span>Veuillez sélectionner au moins un document.</span></div>");
  }
  else 
  {
    var data = $('#comptaAnalysisEdition #compta_analytic_form_modal').serialize()
    data += '&document_ids='+document_ids.join(',')
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

        $("#comptaAnalysisEdition .length_alert").html(full_message);
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
  var document_ids = [];
  $("#lists_pieces > #lists_pieces_content > ul > li.selected").each(function(li){ 
      document_ids.push($(this).attr('id').split("_")[1]); 
  });
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
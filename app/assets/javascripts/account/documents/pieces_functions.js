// showing all pieces of the pack given by link
function showPieces(link, page=1, by_preseizure=null,by_scroll="false") {
  if(page < 1 || window.piecesLoaderLocked)
    return false

  window.piecesLoaderLocked = true;
  var document_id = link.parents("li").attr("id").split("_")[2];
  var source = (link.parents("li").hasClass('report'))? 'report' : 'pack'

  if(by_preseizure === null)
  {
    var filter = '&'+window.getParamsFromFilter();
    window.setParamsFilterText();
  }
  else
  {
    var filter = '&piece_id='+by_preseizure;
  }

  var url = "/account/documents/"+document_id+"?source="+source+"&fetch=pieces&page="+page+filter;

  window.piecesPage = page + 1;
  
  $("#panel3").hide();
  $("#panel1").show();

  getPieces(url, link.text(), by_preseizure,by_scroll);
}

// fecth all pieces of the pack
function getPieces(url,title,by_preseizure=null,by_scroll) {
  $.ajax({
    url: encodeURI(url),
    data: "",
    dataType: "html",
    type: "GET",
    beforeSend: function() {
      logBeforeAction("Traitement en cours");

      var vTitle = "";
      if (title)
        vTitle = title;
      else
        vTitle = "Résultat : ";
      if (by_scroll== "false")
      {
        $("#panel1 .header h3").text(vTitle);
      }
    },
    success: function(data){
      data = data.trim();

      logAfterAction();

      // window.piecesPage == 2 means that we fetched the first result from page 1
      if(window.piecesPage == 2)
      {
        window.preseizuresSelected = [];

        if(data != 'none')
          $("#panel1 > .content").html(data);
        else
          $("#panel1 > .content").html('Aucun résultat');

        if(by_preseizure === null)
          $('#show_pages .showALLPieces').addClass('hide');
        else
          $('#show_pages .showALLPieces').removeClass('hide');

        $("#show_pieces > ul > li:not(:visible)").fadeIn(1500);
      }
      else
      {
        var parser = new DOMParser();
        var htmlDoc = parser.parseFromString(data, 'text/html');
        var data_lists = $(htmlDoc).find('#lists_pieces_content #pages').html();

        if(data != 'none' && data_lists != null && data_lists != undefined && data_lists.trim().length > 0)
          $("#panel1 #lists_pieces #pages").append(data_lists);
        else
          window.piecesPage = -1;
      }

      $("#show_pages #lists_pieces_content > ul > li:not(:visible)").fadeIn(1500);

      initEventOnPiecesRefresh();
      synchroniseSelected();
      initEventOnPreseizuresRefresh();
      getPreseizureAccount();
      initEventOnHoverOnInformation();

      $("#show_pages h4").text($("#show_pages .pieces_total_count").text() + " piece(s) traitée(s)");
      $("#show_pieces h4").text($("#show_pieces > ul > li").length + " piece(s) en cours de traitement");
      if ($(".piece_deleted_count").length > 0)
      {
        $(".piece_deleted_count").appendTo("#panel1 .header h3").removeClass('hide');
      }

      $("#pageslist .thumb img").load(function(){
        $(this).parent('.thumb').css('background', 'none');
      });

      $("#pageslist .thumb img").each(function(index){
        if($(this).complete)
          $(this).load();
      });

      var href_download     = $(".href_download").val();
      var href_zip_download = $(".href_download_zip").val();

      if(href_download != '#')
        $('#panel1 > .pages .actiongroup .download').attr('href', href_download);
      else
        $('#panel1 > .pages .actiongroup .download').removeAttr('href');

      if(href_zip_download != '#')
        $('#panel1 > .pages .actiongroup .zip_download').attr('href', href_zip_download);
      else
        $('#panel1 > .pages .actiongroup .zip_download').removeAttr('href');
      setTimeout(function(){ window.piecesLoaderLocked = false }, 1000);
    },
    error: function(data){
      logAfterAction();
      $(".alerts").html("<div class='row-fluid'><div class='span12 alert alert-danger'><a class='close' data-dismiss='alert'> × </a><span> Une erreur est survenue et l'administrateur a été prévenu.</span></div></div>");
      setTimeout(function(){ window.piecesLoaderLocked = false }, 1000);
    }
  });
}

// show or hide selection field
function toogleSelectionBox(){
  $('#selectionsBox').addClass('hide');
  countSelectedPieces();
  downloadSelectedPieces();
}

// add page to the selection field
function addPage(page) {
  var id = page.attr("id").split("_")[1];
  if (!$("#composition_"+id).length > 0) {
    var li = page.clone();    
    li.removeClass("selected");    
    var ul = li.children(".toolbar").children("ul");
    ul.children("li.selector").remove();
    ul.append("<li><a class='delete do-removePageFromSelection' href='#' title='Supprimer'></a><li>");
    initEventOnPiecesSelection();
  }
  toogleSelectionBox();
}

// remove page from the selection field
function removePage(page) {
  var id = page.attr("id").split("_")[1];
  $("#composition_"+id).remove();
  toogleSelectionBox();
}

//get user softwares parameteres
function initParameters(link) {
  $("a.removeAllSelection").click()

  window.analytic_target_form = '#compta_analytic_form_modal';
  window.uses_ibiza_analytics = link.data('uses-ibiza-analytics');
  window.user_code            = link.data('user-code');
  window.pack_journal         = link.data('pack-journal');

  if(window.uses_ibiza_analytics > 0)
    $('#selectionsBox .compta_analysis_edition').removeClass('hide');
  else
    $('#selectionsBox .compta_analysis_edition').addClass('hide');
}

// show the preview of page given by link
function showPage(link,view="init") {
  var url = link.attr("href");

  var li = link.parents("li");
  var id = li.attr("id").split("_")[1];
  var page_number = (li.prevAll().length + 1);

  var data_content = $('.data-content-view-pdf .content');
  data_content.find('.showPage').val(id);
  data_content.find('.page_number').text(page_number);
  data_content.find('.iframe-content iframe').prop('src',url);
  
  if (view == "init")
  {
    $("#PdfViewerDialog").modal('show');  
  }
  else 
  {
    $("#PdfViewerDialog .modal-body .view-content").html('<img src="/assets/application/spinner_gray_alpha.gif" alt="Chargement">Chargement en cours . . . ');
  }
  
  $("#PdfViewerDialog .modal-body .view-content").html('');
  data_content.clone().appendTo("#PdfViewerDialog .modal-body .view-content");
  initEventOnPiecesRefresh();
}

function ShowPdfView(data_content, show='init')
{
  if (show == 'init')
  {
    $("#PdfViewerDialog").modal('show');
  }
  $("#PdfViewerDialog .modal-body .view-content").html(data_content);
  initEventOnPiecesRefresh();
}
// toggle page selection given by link
function selectPage(link) {
  var li = link.parents("li.pages")
  li.toggleClass("selected");

  if ($("li.selected").length > 0)
  {
    // if ($("li.selected").length >= 2)
    // {
    //   $(".composer").show();
    // }
    // else
    // {
    //   $(".composer").hide();
    // }

    $(".composer").hide();

    $(".compta_analysis_edition, .delete_piece_composition").show();
    $(".delete_piece_composition, .piece_tag, .compta_analysis_edition, .composer, .download").addClass('border_piece_action');
  }
  else 
  {
    $(".compta_analysis_edition, .composer, .delete_piece_composition").hide();
    $(".delete_piece_composition, .piece_tag, .compta_analysis_edition, .composer, .download").removeClass('border_piece_action');
  } 

  if (li.hasClass('selected'))
  {
    link.find('.do-selectPage-check-icon').addClass('hide');
    link.find('.do-selectPage-ban-icon').removeClass('hide');
  }
  else 
  {
    link.find('.do-selectPage-check-icon').removeClass('hide');
    link.find('.do-selectPage-ban-icon').addClass('hide');
  }

  countSelectedPieces();
  downloadSelectedPieces();
}

function Tagging(type_tag='pack::piece') {
  var $selectionsTags = $("#selectionsTags");

  if (type_tag == 'pack::piece'){
    var document_ids = $.map($("#lists_pieces_content ul li.selected"), function(li){ return li.id.split("_")[1] });
  }
  else{
    var document_ids = $.map($(".packsList .content ul li.pack.selected"), function(li){ return li.id.split("_")[1] });
  }

  var list_tag_to_delete = $.map($(".tag_itteration.hide input"), function(input){ return input.value });

  var post_data = null
  if (list_tag_to_delete.length > 0) {
    post_data = $selectionsTags.val() + list_tag_to_delete.toString().replace(/[,]/g, ' ');
  }
  else{
    post_data = $selectionsTags.val()
  }

  if (document_ids.length <= 0)
    $("#selectionTaggingDialog .length_alert").html("<div class='alert alert-danger'><a class='close' data-dismiss='alert'> × </a><span>Veuillez sélectionner au moins un document.</span></div>");
  if ($selectionsTags.val().length <= 0 && list_tag_to_delete.length <= 0)
    $("#selectionTaggingDialog .names_alert").html("<div class='alert alert-danger'><a class='close' data-dismiss='alert'> × </a><span>Veuillez indiquer ou supprimer au moins un tag.</span></div>");

  if ( document_ids.length > 0 && post_data.length > 0) {
    postTags(post_data,document_ids,type_tag);

    $selectionsTags.val("");

    removeSelection();
    countSelectedPieces();
    $("#selectionTaggingDialog").modal("hide");

    if (type_tag == 'pack::piece'){
      $('.pack.shared.activated a.pack_name_selection').click();
    }
  }
};

function removeSelection(){
  $("#lists_pieces_content ul li").removeClass('selected');
  $(".actiongroup a").removeClass('border_piece_action');
  $('.pack.shared').removeClass('selected');
}

// remove the document from selection, given by link
function removePageFromSelection(link) {
  var li = link.parents("li.pages");
  id = li.attr("id").split("_")[1];
  $("#document_"+id).removeClass("selected");
  li.remove();
  toogleSelectionBox();
}

// synchronise the newly shown pages with selection
function synchroniseSelected() {
  $("#selectionlist > .content > ul > li").each(function(index,li) {
    id = $(li).attr("id").split("_")[1];
    $("#pageslist #document_"+id).addClass("selected");
  });
}

// synchronise the removed pages in selection with selected in pages
function synchroniseRemovedSelection() {
  $("#selectionlist > .content > ul > li").each(function(index,li) {
    id = $(li).attr("id").split("_")[1];
    $("#pageslist #document_"+id).removeClass("selected");
  });
}

//get content tag
function get_content_tag(type_tag='piece'){
  if (type_tag == 'piece'){
    var ids = $.map($("#lists_pieces_content ul li.selected"), function(li){ return li.id.split("_")[1] });
  }
  else{
    var ids = $.map($(".packsList .content ul li.pack.selected"), function(li){ return li.id.split("_")[1] });
  }

  countSelectedPieces();

  if (ids.length > 0){
    $("#selectionTaggingDialog").modal('show');
    $("#selectionTaggingDialog .modal-body").html('<div class="feedback text-center"><img class="text-center" src="/assets/application/bar_loading.gif" alt="chargement..." ></div>');

    $.ajax({
      url: "/account/documents/tags/get_tag_content",
      data: { ids: ids, type_tag: type_tag },
      type: "POST",
      success: function(data){
        $("#selectionTaggingDialog .modal-body").html(data);
        initEventOnPiecesRefresh();
      }
    });
  }
}

// submit tag
function postTags(tags,document_ids,type) {
  var hsh = {"document_ids": document_ids, "tags": tags, type: type};
  $.ajax({
    async: false,
    url: "/account/documents/tags/update_multiple",
    data: hsh,
    dataType: "json",
    type: "POST",
    beforeSend: function() {
    },
    success: function(data){
    }
  });
}

function lock_file_upload_params() {
  var title = null;
  if($('#h_file_code').length > 0) {
    title = 'Vous avez sélectionné des documents à ajouter dans un client / type / période, veuillez démarrer le téléchargement avant de changer pour téléverser à nouveau.';
    $('select[name="h_file_code"]').attr('disabled', 'disabled').trigger('chosen:updated');
    $('#h_file_code_chosen').attr('title', title);
  } else {
    title = 'Vous avez sélectionné des documents à ajouter dans un type ou période, veuillez démarrer le téléchargement avant de changer pour téléverser à nouveau.';
  }
  $('select[name="h_file_account_book_type"]').attr('disabled', 'disabled');
  $('select[name="h_file_prev_period_offset"]').attr('disabled', 'disabled');
  $('select[name="h_file_account_book_type"]').attr('title', title);
  $('select[name="h_file_prev_period_offset"]').attr('title', title);
  $('.analytic_name').attr('disabled', 'disabled').attr('title', title);
  $('.analytic_axis').attr('disabled', 'disabled').trigger('chosen:updated');
  $('#analytic .chosen-container').attr('title', title);
}

function unlock_file_upload_params() {
  if($('#h_file_code').length > 0)
    $('select[name="h_file_code"]').removeAttr('disabled').trigger('chosen:updated');
    $('#h_file_code_chosen').removeAttr('title');
  $('select[name="h_file_account_book_type"]').removeAttr('disabled');
  $('select[name="h_file_prev_period_offset"]').removeAttr('disabled');
  $('select[name="h_file_account_book_type"]').removeAttr('title');
  $('select[name="h_file_prev_period_offset"]').removeAttr('title');
  if($('.analytic_name option').length > 1)
    $('.analytic_name').removeAttr('disabled');
  $('.analytic_name').removeAttr('title');
  $('.analytic_axis').removeAttr('disabled').trigger('chosen:updated');
  $('#analytic .chosen-container').removeAttr('title');
}

var isUploadParamsLocked = false;
function lock_or_unlock_file_upload_params() {
    if($('.template-upload').length > 0) {
      if(!isUploadParamsLocked) {
        lock_file_upload_params();
        isUploadParamsLocked = true;
      }
    } else {
      if(isUploadParamsLocked) {
        unlock_file_upload_params();
        isUploadParamsLocked = false;
      }
    }
}

function actionDeletePiece(piece_id){
  $('#confirmDeletePiece .message_confirm').html('<img src="/assets/application/spinner_gray_alpha.gif" alt="Chargement">Traitement en cours . . . ');
  $.ajax({
      url: "/account/documents/delete_multiple_piece",
      data: { piece_id: piece_id },
      type: "POST",        
      success: function(data){        
        $.map(piece_id, function(piece_id,id){            
         $('#document_'+piece_id).remove();              
        }) ; 
        var pagesTitle = $("#show_pages h4");
        var pagesCount = $("ul#pages > li").length; 
        pagesTitle.text(pagesCount + " piece(s) traitée(s)");
        if (pagesCount == 0) pagesTitle.text('');   
        $('#selectionsBox').addClass('hide');
        $('#confirmDeletePiece').modal('hide');
        $('#confirmDeletePiece .message_confirm').html('Voulez-vous vraiment supprimer cette pièce ? ');
      }
    });
}

function deletePiece(piece){
  $('#confirmDeletePiece').off();
  $('#confirmDeletePiece').modal('show').on('click','#deletebutton',function(e){
    e.preventDefault();      
    actionDeletePiece([piece]);
  });
}

function deletePieceComposition(){
  var elements = $('li[id^="document_"].selected')
  if (elements.length > 0)
  {  
    $('#confirmDeletePiece').off();

    $('#confirmDeletePiece .message_confirm').html('Voulez-vous vraiment supprimer la pièce séléctionnée ? ');
    if(elements.length > 1)
      $('#confirmDeletePiece .message_confirm').html('Voulez-vous vraiment supprimer les ' + elements.length + ' pièces séléctionnées ? ');

    $('#confirmDeletePiece').modal('show').on('click','#deletebutton',function(e){
      e.preventDefault();
      var piece_id   = [];
      elements.each(function(i){
        tmp_this     = $(this).attr('id'); 
        piece_id_tmp = tmp_this.split('_');
        piece_id.push(piece_id_tmp[1]);       
      });
      actionDeletePiece(piece_id); 
    });
  }
}

function countSelectedPieces(){
  var selected_items = $("#show_pages li.pages.selected").length;
  var total_count = $('#show_pages .head .pieces_total_count').text() || '0';

  var selected_htm = "<strong class='selected_items_info' style='margin-right: 15px'>" + selected_items + " / " + total_count + " pièce(s) séléctionnée(s)</strong>";

  $('#show_pages .head .actiongroup .selected_items_info').remove();
  if(selected_items > 0)
    $('#show_pages .head .actiongroup a:first').before(selected_htm);
}

function downloadSelectedPieces(){
  var selected_items = $("#show_pages li.pages.selected")
  var total_count    = $('#show_pages .head .pieces_total_count').text() || '0';
  var document_ids   = [];
  var href_download  = $('#panel1 > .pages .actiongroup .download')

  if(selected_items.length > 0 && total_count > selected_items.length){
    selected_items.each(function(li){
      document_ids.push($(this).attr('id').split("_")[1]);
    });

    if(document_ids.length == 1)
      href_download.attr('href', selected_items.find('span.choose_action_piece a:eq(1)').attr('href'));
    else
      href_download.attr('href', '/account/documents/pieces/download_selected/' + document_ids.join('_'));
  } else if(total_count == selected_items.length){
    href_download.attr('href', $(".href_download").val());
  }
}
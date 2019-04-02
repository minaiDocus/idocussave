// showing all pieces of the pack given by link
function showPieces(link, page=1, by_preseizure=null) {
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

  $("#panel2").hide();
  $("#panel3").hide();
  $("#panel1").show();

  getPieces(url, link.text(), by_preseizure);
}

// fecth all pieces of the pack
function getPieces(url,title,by_preseizure=null) {
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
      $("#panel1 .header h3").text(vTitle);
    },
    success: function(data){
      data = data.trim();

      logAfterAction();

      if(window.piecesPage == 2)
      {
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

      //calculate Approximative height of lists content
      var lists_pieces_height = Math.ceil($(window).outerHeight() / 1.2); 

      var img_width   = 121
      var img_height  = 163

      var content_box_width = $('#pageslist').parent().outerWidth();
      var elem_per_row      = Math.ceil(content_box_width / img_width)
      var elem_count        = $('#lists_pieces_content > ul > li').length;
      var rows_count        = Math.ceil(elem_count / elem_per_row);

      var lists_pieces_content_height = rows_count * img_height // height approximative

      //Fetch data until content pieces has not enough space
      var fetch_by_size = (lists_pieces_height > lists_pieces_content_height)? true : false;

      var sTop = $(window).scrollTop();
      var last_element = $('#lists_pieces_content > ul > li:last');

      if(last_element.is(':visible'))
        var offsetTopLast = last_element.offset().top;
      else
        var offsetTopLast = $(window).outerHeight() + 1;

      var realTopLast = offsetTopLast - sTop;
      fetch_from_visible = ($(window).outerHeight() > realTopLast)? true : false;

      if((fetch_by_size || fetch_from_visible) && window.piecesPage > 0)
      { 
        window.piecesLoaderLocked = false;
        setTimeout(showPieces(window.currentLink, window.piecesPage, by_preseizure), 1000);
      }
      else
      {
        initEventOnPiecesRefresh();
        synchroniseSelected();
        window.handleView();

        $("#show_pages h4").text($("#show_pages .pieces_total_count").text() + " piece(s) traitée(s)");
        $("#show_pieces h4").text($("#show_pieces > ul > li").length + " piece(s) en cours de traitement");
      }

      $("#pageslist .thumb img").load(function(){
        $(this).parent('.thumb').css('background', 'none');
      });

      $("#pageslist .thumb img").each(function(index){
        if($(this).complete)
          $(this).load();
      });

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
  lists = btoa($('#selectionsBox #selectionlist ul.list').html().trim());
  if ( lists == '' )
    $('#selectionsBox').addClass('hide');
  else
    $('#selectionsBox').removeClass('hide');
}

// add page to the selection field
function addPage(page) {
  var id = page.attr("id").split("_")[1];
  if (!$("#composition_"+id).length > 0) {
    var li = page.clone();
    li.appendTo("#selectionlist .content > ul").attr("id","composition_"+id);
    li.removeClass("selected");
    li.children(".zoom").remove();
    li.children(".toolbar").after("<div class='handle' title='Déplacer'></div>");
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
function showPage(link) {
  var url = link.attr("href");

  if (link.parents("ul").attr("id") == "pieces")
    var panel = "#panel3"
  else
    var panel = "#panel2"
  $("#panel1").hide();
  $(panel).show();

  $(".actiongroup.group1").hide();
  $(".actiongroup.group2").show();

  $("#pageslist .header h3.all").hide();
  $("#pageslist .header .single").show();

  var li = link.parents("li");
  var id = li.attr("id").split("_")[1];
  var tags = li.children("input[name=tags]").val();
  var name = li.children("input[name=name]").val();
  if (panel == "#panel2")
  {
    var page_number = li.children("input[name=page_number]").val();
    var piece_id    = link.attr('data-piece-id');
    if(piece_id > 0)
    {
      $('#panel2 .actiongroup .do-goToPreseizure').attr('data-id', piece_id);
      $('#panel2 .actiongroup .do-goToPreseizure').removeClass('hide');
    }
    else
    {
      $('#panel2 .actiongroup .do-goToPreseizure').addClass('hide');
    }
  }
  else
  {
    var page_number = (li.prevAll().length + 1);
  }

  $(panel + " .showPage").attr("id",id);
  $(panel + " .showPage").attr("src",url);
  $("#pageInformation").attr("data-content",tags);

  $(panel + ' #stamp_box').addClass('hide')
  if(link.attr("data-stamp-url") != '/assets/'){
    $(panel + ' #stamp_box img').attr("src", link.attr("data-stamp-url"))
    $(panel + ' #stamp_box').removeClass('hide')
  }

  $(panel + " .header h3").text(name);
  $(panel + " .header .actiongroup .page_number").text(page_number);
}

// toggle page selection given by link
function selectPage(link) {
  var li = link.parents("li.pages")
  li.toggleClass("selected");
  if (li.hasClass("selected")) {
    addPage(li);
  } else {
    removePage(li);
  }
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

// submit tag
function postTags(tags,document_ids,type) {
  var hsh = {"document_ids": document_ids, "tags": tags, type: type};
  $.ajax({
    url: "/account/documents/tags/update_multiple",
    data: hsh,
    dataType: "json",
    type: "POST",
    beforeSend: function() {
      logBeforeAction("Traitement en cours");
    },
    success: function(data){
      logAfterAction();
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

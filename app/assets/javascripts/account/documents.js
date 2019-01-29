(function($) {
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
      initEventOnClickOnLinkButton();
    }
    toogleSelectionBox();
  }

  // remove page from the selection field
  function removePage(page) {
    var id = page.attr("id").split("_")[1];
    $("#composition_"+id).remove();
    toogleSelectionBox();
  }

  // showing all pieces of the pack given by link
  function showPieces(link) {
    var document_id = link.parents("li").attr("id").split("_")[2];

    var filter = $("#filter").val();
    if (filter != "")
      filter = "?filter="+filter;
    var url = "/account/documents/"+document_id+filter;

    $("#panel2").hide();
    $("#panel3").hide();
    $("#panel1").show();
    getPieces(url,link.text());
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
      var page_number = li.children("input[name=page_number]").val();
    else
      var page_number = (li.prevAll().length + 1);

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

  // get packs of page given by link
  function showPacks(link) {
    var page = 1;
    var regexp = new RegExp("page=[0-9]+");
    var regexp2 = new RegExp("[0-9]+");
    result = regexp2.exec(regexp.exec(link.attr("href").replace(/per_page=\d/,"")));
    if (result != null)
      page = result[0];
    getPacks(page);
  }

  // fecth all pieces of the pack
  function getPieces(url,title) {
    $.ajax({
      url: encodeURI(url),
      data: "",
      dataType: "html",
      type: "GET",
      beforeSend: function() {
        logBeforeAction("Traitement en cours");
        $("#panel1 > .content").html("");
      },
      success: function(data){
        logAfterAction();
        $("#panel1 > .content").html("");
        $("#panel1 > .content").append(data);
        initEventOnClickOnLinkButton();
        initEventOnHoverOnInformation();
        synchroniseSelected();
        $("#pageslist").attr("style","min-height:"+$("#documentslist").height()+"px");

        $("#pageslist .thumb img").load(function(){
          $(this).parent('.thumb').css('background', 'none');
        });

        $("#pageslist .thumb img").each(function(index){
          if($(this).complete)
            $(this).load();
        });

        var viewTitle = $("#panel1 .header h3");
        var vTitle = "";
        if (title)
          vTitle = title;
        else
          vTitle = "Résultat : ";

        var pagesTitle = $("#show_pages h4");
        var pagesCount = $("#show_pages > ul > li").length;
        var piecesTitle = $("#show_pieces h4");
        var piecesCount = $("#show_pieces >ul > li").length;

        viewTitle.text(vTitle);
        pagesTitle.text(pagesCount + " piece(s)");
        piecesTitle.text(piecesCount + " piece(s) en cours de traitement");
      },
      error: function(data){
        logAfterAction();
        $(".alerts").html("<div class='row-fluid'><div class='span12 alert alert-error'><a class='close' data-dismiss='alert'> × </a><span> Une erreur est survenue et l'administrateur a été prévenu.</span></div></div>");
      }
    });
  }

  // fetch list of packs
  function getPacks(PAGE) {
    var filter = $("#filter").val();
    if (filter != "")
      filter = ";filter="+filter;
    var view = $("select[name=document_owner_list]").val();
    var per_page = $("select[name=per_page]").val();
    var page = typeof(PAGE) != 'undefined' ? PAGE : 1;

    if (view == 'current_delivery') {
      $('a.delivery').hide();
    } else {
      $('a.delivery').show();
    }
    $("#panel1 .header h3").text('Pages');
    $("#panel1 > .content").html("");

    var Url = "/account/documents/packs?page="+page+";view="+view+";per_page="+per_page+filter;

    $.ajax({
      url: encodeURI(Url),
      data: "",
      dataType: "html",
      type: "GET",
      beforeSend: function() {
        logBeforeAction("Traitement en cours");
      },
      success: function(data) {
        logAfterAction();
        var list = $("#documentslist .content");
        list.children("*").remove();
        list.append(data);
        $("#panel2").hide();
        $("#panel3").hide();
        $("#panel1").show();

        packs_count = $("input[name=packs_count]").val();
        $("#documentslist > .header > h3").text(packs_count + " document(s)");

        $("#pageslist").attr("style","min-height:"+$("#documentslist").height()+"px");

        initEventOnClickOnLinkButton();
        initEventOnHoverOnInformation();
      },
      error: function(data){
        logAfterAction();
        $(".alerts").html("<div class='row-fluid'><div class='span12 alert alert-error'><a class='close' data-dismiss='alert'> × </a><span> Une erreur est survenue et l'administrateur a été prévenu.</span></div></div>");
      }
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

  // init all link action
  function initEventOnClickOnLinkButton() {
    $("a.do-show").unbind("click");
    $("a.do-show").bind("click",function() {
      showPieces($(this));
      initParameters($(this));
      return false;
    });

    $("a.do-selectPage").unbind("click");
    $("a.do-selectPage").bind("click",function() {
      selectPage($(this));
      return false;
    });

    $("a.do-removePageFromSelection").unbind("click");
    $("a.do-removePageFromSelection").bind("click",function() {
      removePageFromSelection($(this));
      return false;
    });

    $(".pagination a").unbind('click');
    $(".pagination a").bind('click',function() {
      if(!$(this).parents('li').hasClass('disabled') && !$(this).parents('li').hasClass('active'))
        showPacks($(this));
      return false;
    });

    $("a.do-showPage").unbind('click');
    $("a.do-showPage").bind('click',function() {
      showPage($(this));
      return false;
    });

    $("a.do-select").unbind("click");
    $("a.do-select").bind("click",function(){ $(this).parents("li").toggleClass("selected"); return false; });
  }

  function initEventOnHoverOnInformation() {
    $('.do-tooltip, .information, .do-tooltip-top, .information-top').tooltip({placement: 'top', trigger: 'hover'});
    $('.do-tooltip-right, .information-right').tooltip({placement: 'left', trigger: 'hover'});
    $('.do-tooltip-bottom, .information-bottom').tooltip({placement: 'left', trigger: 'hover'});
    $('.do-tooltip-left, .information-left').tooltip({placement: 'left', trigger: 'hover'});
    $('.do-popover-top').popover({placement: 'top'});
    $('.do-popover, .do-popover-right').popover({placement: 'right'});
    $('.do-popover-bottom').popover({placement: 'bottom'});
    $('.do-popover-left').popover({placement: 'left'});
  }

  // initialize once
  function initManager() {
    $("#filter").change(function(){
      $("#panel1 .header h4").text("");
      $("#panel1 .content ul").html("");
      getPacks();
    });

    $("#documentsTaggingButton").click(function(e) {
      e.preventDefault();
      var document_ids = $.map($("#documentslist > .content > ul > li.selected"), function(li){ return li.id.split("_")[1] });
      var $documentsTags = $("#documentsTags");

      if (document_ids.length <= 0)
        $("#documentsTaggingDialog .length_alert").html("<div class='alert alert-error'><a class='close' data-dismiss='alert'> × </a><span>Veuillez sélectionner au moins un document.</span></div>");
      if ($documentsTags.val().length <= 0)
        $("#documentsTaggingDialog .names_alert").html("<div class='alert alert-error'><a class='close' data-dismiss='alert'> × </a><span>Veuillez indiquer au moins un tag.</span></div>");

      if (document_ids.length > 0 && $documentsTags.val().length > 0) {
        var tags = $documentsTags.val();
        $documentsTags.val("");
        postTags(tags,document_ids,'pack');
        aTags = tags.split(" ");
        $("#documentslist > .content > ul > li.selected").each(function(i,li) {
          var $link = $(li).children(".action").children(".do-popover");
          var $content = $($link.attr("data-content"));
          var oTags = $content.find('.tags').text();

          for ( var i=0; i<aTags.length; ++i ) {
            if (aTags[i].match("-")) {
              pattern = "\\s" + aTags[i].replace("-","").replace("*",".*");
              var reg = new RegExp(pattern,"g");
              oTags = oTags.replace(reg,"");
            } else {
              if (!oTags.match(aTags[i])) {
                oTags = oTags + " " + aTags[i];
              }
            }
          }
          $content.find('.tags').text(oTags);
          $link.attr("data-content", '<div>'+$content.html()+'</div>');
        });
        $("#documentsTaggingDialog").modal('hide');
      }
    });

    $("#documentsTaggingDialog").on("hidden",function() {
      $("#documentsTaggingDialog .length_alert").html("");
      $("#documentsTaggingDialog .names_alert").html("");
      $("#documentsTags").val("");
    });

    $("#documentsTags").change(function() {
      $("#documentsTaggingDialog .names_alert").html("");
    });

    $("#pagesTaggingButton").click(function(e) {
      e.preventDefault();
      var $documents = $("#show_pages li.selected");
      var document_ids = $.map($documents, function(li){ return li.id.split("_")[1] });
      var $pagesTags = $("#pagesTags");

      if (document_ids.length <= 0)
        $("#pagesTaggingDialog .length_alert").html("<div class='alert alert-error'><a class='close' data-dismiss='alert'> × </a><span>Veuillez sélectionner au moins un document.</span></div>");
      if ($pagesTags.val().length <= 0)
        $("#pagesTaggingDialog .names_alert").html("<div class='alert alert-error'><a class='close' data-dismiss='alert'> × </a><span>Veuillez indiquer au moins un tag.</span></div>");

      if (document_ids.length > 0 && $pagesTags.val().length > 0) {
        postTags($pagesTags.val(),document_ids,'piece');
        var aTags = $pagesTags.val().split(' ');
        for(var k=0; k<$documents.length; k++ ) {
          var $document = $($documents[k]);
          tags = $document.find('input[name=tags]').val();
          for ( var i=0; i<aTags.length; ++i ) {
            if (aTags[i].match("-")) {
              pattern = "\\s" + aTags[i].replace("-","").replace("*",".*");
              var reg = new RegExp(pattern,"g");
              tags = tags.replace(reg,"");
            } else {
              if (!tags.match(aTags[i])) {
                tags = tags + " " + aTags[i];
              }
            }
          }
          $document.find('input[name=tags]').val(tags);
        }
        $pagesTags.val("");
        $("#pagesTaggingDialog").modal("hide");
      }
    });

    $("#pagesTaggingDialog").on("hidden",function() {
      $("#pagesTaggingDialog .length_alert").html("");
      $("#pagesTaggingDialog .names_alert").html("");
      $("#pagesTags").val("");
    });

    $("#pagesTags").change(function() {
      $("#pagesTaggingDialog .names_alert").html("");
    });

    $("#selectionsTaggingButton").click(function(e){
      e.preventDefault();
      var document_ids = $.map($("#selectionlist > .content > ul > li"), function(li){ return li.id.split("_")[1] });
      var $documents = $($.map(document_ids, function(id) { return '#document_' + id }).join(','));
      var $selectionsTags = $("#selectionsTags");

      if (document_ids.length <= 0)
        $("#selectionTaggingDialog .length_alert").html("<div class='alert alert-error'><a class='close' data-dismiss='alert'> × </a><span>Veuillez sélectionner au moins un document.</span></div>");
      if ($selectionsTags.val().length <= 0)
        $("#selectionTaggingDialog .names_alert").html("<div class='alert alert-error'><a class='close' data-dismiss='alert'> × </a><span>Veuillez indiquer au moins un tag.</span></div>");

      if (document_ids.length > 0 && $selectionsTags.val().length > 0) {
        postTags($selectionsTags.val(),document_ids,'piece');
        var aTags = $selectionsTags.val().split(' ');
        for(var k=0; k<$documents.length; k++ ) {
          var $document = $($documents[k]);
          tags = $document.find('input[name=tags]').val();
          for ( var i=0; i<aTags.length; ++i ) {
            if (aTags[i].match("-")) {
              pattern = "\\s" + aTags[i].replace("-","").replace("*",".*");
              var reg = new RegExp(pattern,"g");
              tags = tags.replace(reg,"");
            } else {
              if (!tags.match(aTags[i])) {
                tags = tags + " " + aTags[i];
              }
            }
          }
          $document.find('input[name=tags]').val(tags);
        }
        $selectionsTags.val("");
        $("#selectionTaggingDialog").modal("hide");
      }
    });

    $("#selectionTaggingDialog").on("hidden",function() {
      $("#selectionTaggingDialog .length_alert").html("");
      $("#selectionTaggingDialog .names_alert").html("");
      $("#selectionsTags").val("");
    });

    $("#selectionsTags").change(function() {
      $("#selectionTaggingDialog .names_alert").html("");
    });

    $("#compositionButton").click(function() {
      var document_ids = $.map($("#selectionlist > .content > ul > li"), function(li){ return li.id.split("_")[1] });
      var $composition_name = $("#composition_name");

      if (document_ids.length <= 0)
        $("#compositionDialog .length_alert").html("<div class='alert alert-error'><a class='close' data-dismiss='alert'> × </a><span>Veuillez sélectionner au moins un document.</span></div>");
      if ($composition_name.val().length <= 0)
        $("#compositionDialog .names_alert").html("<div class='alert alert-error'><a class='close' data-dismiss='alert'> × </a><span>Veuillez indiquer le nom de la composition.</span></div>");

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

    $('#analysis_validate').on('click', function(){
      var document_ids = $.map($("#selectionlist > .content > ul > li"), function(li){ return li.id.split("_")[1] });
      if (document_ids.length <= 0)
      {
        $("#comptaAnalysisEdition .length_alert").html("<div class='alert alert-error'><a class='close' data-dismiss='alert'> × </a><span>Veuillez sélectionner au moins un document.</span></div>");
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
              full_message += "<div class='alert alert-error'><a class='close' data-dismiss='alert'> × </a><span>" + data.error_message + "</span></div>";
            } else {
              setTimeout(function(){ $('#comptaAnalysisEdition').modal('hide') }, 2000)
            }

            $("#comptaAnalysisEdition .length_alert").html(full_message)
          },
          error: function(data){
            logAfterAction();
            $('#comptaAnalysisEdition .analytic_validation_loading').addClass('hide');
            $("#comptaAnalysisEdition .length_alert").html("<div class='alert alert-error'><a class='close' data-dismiss='alert'> × </a><span> Une erreur est survenue et l'administrateur a été prévenu.</span></div>");
          }
        });
      }
    })

    $("#compositionDialog").on("hidden",function() {
      $("#compositionDialog .length_alert").html("");
      $("#compositionDialog .names_alert").html("");
      $("#composition_name").val("");
    });

    $("#composition_name").change(function() {
      $("#compositionDialog .names_alert").html("");
    });

    $("#shareDialog").on('show',function(){
      var pack_ids = $.map($("#documentslist > .content > ul > li.selected"), function(li){ return li.id.split("_")[2] });
      if(pack_ids.length > 0) {
        $(".warn_selected_file").show();
        $(".warn_all_file_selected").hide();
      } else {
        $(".warn_all_file_selected").show();
        $(".warn_selected_file").hide();
      }
    });

    $("#download_multi_pack").click(function(){
      $(".alerts").html('')
      var pack_ids = $.map($("#documentslist > .content > ul > li.selected"), function(li){ return li.id.split("_")[2] });
      if(pack_ids != "")
        window.location = "/account/documents/multi_pack_download?pack_ids=" + pack_ids.join('_')
      else
        $(".alerts").html("<div class='row-fluid'><div class='span12 alert alert-error'><a class='close' data-dismiss='alert'> × </a><span>Veuillez selectionner au moins un document.</span></div></div>");
    })

    $("#deliverButton").click(function() {
      var pack_ids = $.map($("#documentslist > .content > ul > li.selected"), function(li){ return li.id.split("_")[2] });
      var view = $("select[name=document_owner_list]").val();
      var delivery_type = $("input[name=delivery_type]:checked").val();
      var hsh = { "filter": $("#filter").val(), "pack_ids": pack_ids, "view": view, "type": delivery_type };
      $.ajax({
        url: "/account/documents/sync_with_external_file_storage",
        data: hsh,
        dataType: "json",
        type: "POST",
        beforeSend: function() {
          logBeforeAction("Traitement en cours");
          $("#deliverButton").attr("disabled","disabled");
        },
        success: function(data){
          logAfterAction();
          $(".alerts").html("<div class='row-fluid'><div class='span12 alert alert-success'><a class='close' data-dismiss='alert'> × </a><span> Vos documents vous seront livrés dès que possible.</span></div></div>");
          $('#shareDialog').modal('hide');
          $("#deliverButton").removeAttr("disabled");
        },
        error: function(data){
          logAfterAction();
          $(".alerts").html("<div class='row-fluid'><div class='span12 alert alert-error'><a class='close' data-dismiss='alert'> × </a><span> Erreur interne, l'administrateur a été prévenu.</span></div></div>");
          $('#shareDialog').modal('hide');
          $("#deliverButton").removeAttr("disabled");
        }
      });
    });
  }

  $(document).ready(function() {
    initManager();
    initEventOnClickOnLinkButton();
    initEventOnHoverOnInformation();

    $("#invoice-show").css("height",(document.body.scrollHeight-50)+"px");
    $("#invoice-show").css("width",(document.body.clientWidth-5)+"px");
    $(window).resize(function() {
      $("#invoice-show").css("height",(document.body.scrollHeight-50)+"px");
      $("#invoice-show").css("width",(document.body.clientWidth-5)+"px");
    });

    $(".view_for").change(function() {
      getPacks();
    });

    $(".per_page").change(function() {
      getPacks();
    });

    $("a.do-selectSinglePage").click(function(e){
      e.preventDefault();
      var id = "#document_" + $(".showPage").attr("id");
      var li = $(id);
      li.addClass("selected");
      addPage(li);
    });
    $("a.do-unselectSinglePage").click(function(e){
      e.preventDefault();
      var id = "#document_" + $(".showPage").attr("id");
      var li = $(id);
      li.removeClass("selected");
      removePage(li);
    });

    $(".modal-close").click(function(){ $(".modal").modal("hide"); });
    $(".close").click(function(){ $(this).parents("li").remove(); });

    // selection event handler
    $(".do-selectAll").click(function(e){ e.preventDefault(); $("#documentslist > .content > ul > li").addClass("selected"); });
    $(".do-unselectAll").click(function(e){ e.preventDefault(); $("#documentslist > .content > ul > li").removeClass("selected"); });

    $("#pageslist").attr("style","min-height:"+$("#documentslist").height()+"px");

    $(".do-selectAllPages").click(function(e){
      e.preventDefault();
      $("#show_pages li.pages").each(function(index,li){
        if (!$(li).hasClass("selected")) {
          $(li).addClass("selected");
          addPage($(li));
        }
      });
    });
    $(".do-unselectAllPages").click(function(e){
      e.preventDefault();
      $("#show_pages li.pages").removeClass("selected");
      $("#show_pages li.pages").each(function(index,li){
        removePage($(li));
      });
    });

    $("#panel2 a.do-nextPage").click(function(e){
      e.preventDefault();
      var id = $("#panel2 .showPage").attr("id");
      var li = $("#document_"+id);
      var link = li.next().children(".do-showPage");
      if (link.length > 0)
        showPage(link);
    });
    $("#panel2 a.do-prevPage").click(function(e){
      e.preventDefault();
      var id = $("#panel2 .showPage").attr("id");
      var li = $("#document_"+id);
      var link = li.prev().children(".do-showPage")
      if (link.length > 0)
        showPage(link);
    });

    $("#panel3 a.do-nextPage").click(function(e){
      e.preventDefault();
      var id = $("#panel3 .showPage").attr("id");
      var li = $("#document_"+id);
      var link = li.next().children(".do-showPage");
      if (link.length > 0)
        showPage(link);
    });
    $("#panel3 a.do-prevPage").click(function(e){
      e.preventDefault();
      var id = $("#panel3 .showPage").attr("id");
      var li = $("#document_"+id);
      var link = li.prev().children(".do-showPage")
      if (link.length > 0)
        showPage(link);
    });

    $(".backToPanel1").click(function(){
      $("#panel2").hide();
      $("#panel3").hide();
      $("#panel1").show();

      $(".actiongroup.group1").show();
      $(".actiongroup.group2").hide();
      return false;
    });

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
          $(".alerts").html("<div class='row-fluid'><div class='span12 alert alert-error'><a class='close' data-dismiss='alert'> × </a><span> Une erreur est survenue et l'administrateur a été informé.</span></div></div>");
        }
      });
    });

    $("#selectionlist .content ul").sortable({
      handle: '.handle'
    });

    // do_qtip(["left bottom"],["top right"],["#documentslist"],["#help1"],["jtools"]);

    if ($('#h_file_code').length > 0) {
      var file_upload_params = $('#fileupload').data('params')
      var analytics = null;

      function file_upload_update_fields(code) {
        var account_book_types = file_upload_params[code]['journals'];
        var content = '';
        for (var i=0; i<account_book_types.length; i++) {
          content = content + "<option value=" + account_book_types[i] + ">" + account_book_types[i] + "</option>";
        }
        $('#h_file_account_book_type').html(content);

        var periods = file_upload_params[code]['periods'];
        content = '';
        for (var i=0; i<periods.length; i++) {
          content = content + "<option value=" + periods[i][1] + ">" + periods[i][0] + "</option>";
        }
        $('#h_file_prev_period_offset').html(content);

        if (file_upload_params[code]['message'] != undefined) {
          $('.prev_period_offset .help-block .period').html(file_upload_params[code]['message']['period']);
          $('.prev_period_offset .help-block .date').html(file_upload_params[code]['message']['date']);
          $('.prev_period_offset .help-block').show();
        } else {
          $('.prev_period_offset .help-block').hide();
        }

        window.setAnalytics(code, $('#h_file_account_book_type').val(), 'journal', file_upload_params[code]['is_analytic_used']);
      }

      $('#h_file_code').on('change', function() {
        if ($(this).val() != '') {
          file_upload_update_fields($(this).val());
          $('#file_code').val($(this).val());
          $('#file_account_book_type').val($('#h_file_account_book_type').val());
          $('#file_prev_period_offset').val($('#h_file_prev_period_offset').val());
        } else {
          $('#file_code').val('');
          $('#file_account_book_type').val('');
          $('#file_prev_period_offset').val('');
          $('#h_file_account_book_type').html('');
          $('#h_file_prev_period_offset').html('');
          window.cleanAnalytics();
        }
      });
    }

    $('#file_account_book_type').val($('#h_file_account_book_type').val());
    $('#file_prev_period_offset').val($('#h_file_prev_period_offset').val());

    $('#h_file_account_book_type').on('change', function() {
      code = $('#h_file_code').val();
      $('#file_account_book_type').val($(this).val());

      var use_analytics = true;
      if(file_upload_params[code] != undefined)
        use_analytics = file_upload_params[code]['is_analytic_used'];

      window.setAnalytics(code, $(this).val(), 'journal', use_analytics);
    });

    $('#h_file_prev_period_offset').on('change', function() {
      $('#file_prev_period_offset').val($(this).val());
    });

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

    var lock_or_unlock_file_upload_params_interval = null;

    $('#uploadDialog').on('show', function() {
      window.analytic_target_form = '#fileupload'
      lock_or_unlock_file_upload_params_interval = setInterval(lock_or_unlock_file_upload_params, 500);
    })

    $('#uploadDialog').on('shown', function() {
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
    })

    $('#uploadDialog').on('hide', function() {
      window.analytic_target_form = null
      clearInterval(lock_or_unlock_file_upload_params_interval);
    })

    $('#comptaAnalysisEdition').on('show', function() {
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
    })

    $('#comptaAnalysisEdition').on('hide', function() {
      $("#comptaAnalysisEdition .length_alert").html('');

      if(window.analytic_target_form == '#fileupload'){
        $("#uploadDialog .analytic_resume_box").html(window.getAnalyticsResume());
        $('#analytic_user_fields .with_default_analysis').hide();
      }
    })

    $('#document_owner_list').chosen({
      search_contains: true,
      no_results_text: 'Aucun résultat correspondant à',
      inherit_select_classes: true
    })

    if($('#pack').length > 0) {
      var url = '/account/documents/' + $('#pack').data('id');
      $("#panel2").hide();
      $("#panel3").hide();
      $("#panel1").show();
      getPieces(url, $('#pack').data('name'));
    }
  });

})(jQuery);

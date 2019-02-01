(function($) {
  //FUNCTION DECLARATION
  // init all link action
  window.initEventOnHoverOnInformation = function() {
    $('.do-tooltip, .information, .do-tooltip-top, .information-top').tooltip({placement: 'top', trigger: 'hover'});
    $('.do-tooltip-right, .information-right').tooltip({placement: 'left', trigger: 'hover'});
    $('.do-tooltip-bottom, .information-bottom').tooltip({placement: 'left', trigger: 'hover'});
    $('.do-tooltip-left, .information-left').tooltip({placement: 'left', trigger: 'hover'});
    $('.do-popover-top').popover({placement: 'top'});
    $('.do-popover, .do-popover-right').popover({placement: 'right'});
    $('.do-popover-bottom').popover({placement: 'bottom'});
    $('.do-popover-left').popover({placement: 'left'});
  }

  window.handleView = function(url=null){
    if(window.currentView == 'pieces')
    {
      $('#documents_view #pieces_view').click();

      $("#panel2").hide();
      $("#panel3").hide();
      $("#panel1").show();
    }
    else
    {
      $('#documents_view #preseizures_view').click();
    }
  }

  function initEventOnPackRefresh(){
    $("a.do-show").unbind("click");
    $("a.do-show").bind("click",function() {
      window.currentLink = $(this);

      $('#presPanel2 #preseizuresFilterForm')[0].reset();

      showPieces(window.currentLink);
      initParameters(window.currentLink);
      getPreseizures(window.currentLink, 1, null, false);

      $("#panel1 > .content").html("");
      $("#presPanel1 > .content").html("");

      return false;
    });

    $("a.do-select").unbind("click");
    $("a.do-select").bind("click",function(){ $(this).parents("li").toggleClass("selected"); return false; });

    $(".pagination a").unbind('click');
    $(".pagination a").bind('click',function() {
      if(!$(this).parents('li').hasClass('disabled') && !$(this).parents('li').hasClass('active'))
        showPacks($(this));
      return false;
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

    $('#documentslist .content').html('');
    getPacks(page);
  }

  // fetch list of packs
  function getPacks(PAGE) {
    var filter = getFilterParams();

    var view = $("select[name=document_owner_list]").val();
    var per_page = $("select[name=per_page]").val();
    var page = typeof(PAGE) != 'undefined' ? PAGE : 1;

    if (view == 'current_delivery') {
      $('a.delivery').hide();
    } else {
      $('a.delivery').show();
    }

    $("#panel1 .header h3").text('Pieces');
    $("#panel1 > .content").html("");

    $("#presPanel1 .header h3").text('Ecritures comptables')
    $("#presPanel1 > .content").html("")

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

        packs_count = $("input[name=packs_count]").val();
        
        $("#documentslist > .header > h3").text(packs_count + " document(s)");

        $("#pageslist #panel1").attr("style","min-height:"+$("#documentslist").height()+"px");
        $("#preseizureslist #presPanel1").attr("style","min-height:"+$("#documentslist").height()+"px");

        window.handleView();
        initEventOnPackRefresh();
        window.initEventOnHoverOnInformation();
      },
      error: function(data){
        logAfterAction();
        $(".alerts").html("<div class='row-fluid'><div class='span12 alert alert-error'><a class='close' data-dismiss='alert'> × </a><span> Une erreur est survenue et l'administrateur a été prévenu.</span></div></div>");
      }
    });
  }

  // initialize once
  function initManager() {
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

    $('#document_owner_list').chosen({
      search_contains: true,
      no_results_text: 'Aucun résultat correspondant à',
      inherit_select_classes: true
    });

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
    });

    $(".do-selectAll").click(function(e){ e.preventDefault(); $("#documentslist > .content > ul > li").addClass("selected"); });
    $(".do-unselectAll").click(function(e){ e.preventDefault(); $("#documentslist > .content > ul > li").removeClass("selected"); });

    $(".modal-close").click(function(){ $(".modal").modal("hide"); });
    $(".close").click(function(){ $(this).parents("li").remove(); });

    $("#selectionlist .content ul").sortable({
      handle: '.handle'
    });

    $(".view_for").change(function() {
      getPacks();
    });

    $(".per_page").change(function() {
      getPacks();
    });

    if ($('#h_file_code').length > 0) {
      var file_upload_params = $('#fileupload').data('params')
      var analytics = null;

      function file_upload_update_fields(code) {
        var account_book_types = file_upload_params[code]['journals'];
        var journals_compta_processable = file_upload_params[code]['journals_compta_processable'] || [];
        var content = '';

        for (var i=0; i<account_book_types.length; i++) {
          var name = account_book_types[i].split(' ')[0].trim();
          var compta_processable = journals_compta_processable.includes(name)? '1':'0';

          content = content + "<option compta-processable=" + compta_processable  +" value=" + name + ">" + account_book_types[i] + "</option>";
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
          $('#h_file_account_book_type').change();

          $('#file_prev_period_offset').val($('#h_file_prev_period_offset').val());
          $('#h_file_prev_period_offset').change();
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

    $('#h_file_account_book_type').on('change', function() {
      code = $('#h_file_code').val();
      $('#file_account_book_type').val($(this).val());

      var option_processable = $(this).find('option[value="'+$(this).val()+'"]').attr('compta-processable')
      if( option_processable == '1' )
        $('#fileupload #compta_processable').css('display', 'none');
      else
        $('#fileupload #compta_processable').css('display', 'block');

      var use_analytics = true;
      if(file_upload_params[code] != undefined)
        use_analytics = file_upload_params[code]['is_analytic_used'];

      window.setAnalytics(code, $(this).val(), 'journal', use_analytics);
    });

    $('#h_file_prev_period_offset').on('change', function() {
      $('#file_prev_period_offset').val($(this).val());
    });


    $('#documents_view #pieces_view').click(function(){
      window.currentView = 'pieces';
      $("#pageslist").fadeIn('slow');
      $("#preseizureslist").hide();
      $('#documents_view .block_view').removeClass('active');
      $('#documents_view #pieces_view ').addClass('active');
    });

    $('#documents_view #preseizures_view').click(function(){
      window.currentView = 'preseizures';
      $("#preseizureslist #presPanel1").attr("style","min-height:"+$("#documentslist").height()+"px;");
      $("#preseizureslist").fadeIn('slow');
      $("#pageslist").hide();
      $('#documents_view .block_view').removeClass('active');
      $('#documents_view #preseizures_view ').addClass('active');
    });


    $(window).resize(function() {
      $("#invoice-show").css("height",(document.body.scrollHeight-50)+"px");
      $("#invoice-show").css("width",(document.body.clientWidth-5)+"px");
    });

    $(window).scroll(function(e){
      if(window.currentLink === null || window.currentLink === undefined)
        return false;

      var sTop       = $(window).scrollTop();
      var diffHeight = 0
      if(window.currentView == 'pieces')
      {
        diffHeight = $('#lists_pieces #lists_pieces_content').outerHeight() - $(window).outerHeight();
        if(sTop >= (diffHeight - 25))
          showPieces(window.currentLink, window.piecesPage);
      }
      else if(window.currentView == 'preseizures')
      {
        diffHeight = $('#lists_preseizures #lists_preseizures_content').outerHeight() - $(window).outerHeight();
        if(sTop >= (diffHeight - 25))
          getPreseizures(window.currentLink, window.preseizuresPage);
      }
    });
  }

  _require('/assets/account/documents/pieces_functions.js');
  _require('/assets/account/documents/preseizures_functions.js');

// DOCUMENT READY

  $(document).ready(function() {
    //SET local Function to GLOBAL
    window.currentView = 'pieces';
    window.preseizuresPage = 1;
    window.piecesPage = 1;
    window.currentLink = null;
    window.preseizuresSelected = [];
    window.piecesLoaderLocked = false;
    window.preseizuresLoaderLocked = false;

    _require('/assets/account/documents/pieces_event_handler.js');
    _require('/assets/account/documents/preseizures_event_handler.js');

    //View Initializers
    initManager();

    initEventOnPackRefresh();
    window.initEventOnHoverOnInformation();

    $("#pageslist #panel1").attr("style","min-height:"+$("#documentslist").height()+"px");
    $("#preseizureslist #presPanel1").attr("style","min-height:"+$("#documentslist").height()+"px");

    $("#invoice-show").css("height",(document.body.scrollHeight-50)+"px");
    $("#invoice-show").css("width",(document.body.clientWidth-5)+"px");

    if($('#pack').length > 0) {
      var url = '/account/documents/' + $('#pack').data('id');
      getPieces(url, $('#pack').data('name'));
    }
  });

})(jQuery);

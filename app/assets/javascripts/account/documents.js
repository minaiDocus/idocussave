(function($) {
  //FUNCTION DECLARATION
  // init all link action
  window.initEventOnHoverOnInformation = function() {
    adjustIconColorDocument();

    $('.do-tooltip, .information, .do-tooltip-top, .information-top').tooltip({ placement: 'top', trigger: 'hover', html: true, sanitize: false });
    $('.do-tooltip-right, .information-right').tooltip({ placement: 'right', trigger: 'hover', html: true, sanitize: false });
    $('.do-tooltip-bottom, .information-bottom').tooltip({ placement: 'bottom', trigger: 'hover', html: true, sanitize: false });
    $('.do-tooltip-left, .information-left').tooltip({ placement: 'left', trigger: 'hover', html: true, sanitize: false });

    $('.do-popover-top').popover({ placement: 'top', trigger: 'hover', html: true, sanitize: false });
    $('.do-popover, .do-popover-right').popover({ placement: 'right', trigger: 'hover', html: true, sanitize: false});
    $('.do-popover-bottom').popover({ placement: 'bottom', trigger: 'hover', html: true, sanitize: false });
    $('.do-popover-left').popover({ placement: 'left', trigger: 'hover', html: true, sanitize: false });

    $('.custom_popover').custom_popover();
  }

  window.getParamsFromFilter = function(){
    window.filterText = '';

    $('#packFilterModal #packFilterForm .input_with_operation').each(function(){
      if( $(this).val() === '' || $(this).val() === undefined || $(this).val() === null )
      {
        $(this).attr('disabled', 'disabled');
        $(this).parent().find('.select_operation').attr('disabled', 'disabled');
      }
    });

    var params_array = $('#packFilterModal #packFilterForm').serializeArray();
    var params_filtered = [];

    params_array.forEach(function(elem){
      if(elem.value !== '' && elem.value !== null && elem.value !== undefined)
      {
        var lbl_for = elem.name.replace('[', '_').replace(']', '');
        var value = $('#packFilterModal #packFilterForm').find('select[name="'+elem.name+'"] option:selected').text() || null;
        var label = $('#packFilterModal #packFilterForm').find("label[for='"+lbl_for+"']").text() || null;

        if(label !== null)
        {
          var operation = $('#packFilterModal #packFilterForm').find('select[id="'+lbl_for+'_operation"] option:selected').text() || '=';
          window.filterText += label + ' ' + operation + ' <i>' + (value || elem.value) + '</i> ; ';
        }

        params_filtered.push(elem.name + '=' + elem.value);
      }
    });


    $('#packFilterModal #packFilterForm .input_with_operation').removeAttr('disabled');
    $('#packFilterModal #packFilterForm .select_operation').removeAttr('disabled');

    return params_filtered.join('&') || '';
  }

  window.setParamsFilterText = function(){
    if(window.filterText != '')
    {
      bdColor = '#aaa';
      if(window.currentTargetFilter == 'all')
        bdColor = '#CB413B';

      $('#documents_actions .filter_indication').attr('style', 'display: inline-block; border: 1px solid '+bdColor);
      $('#documents_actions .filter_indication_text').html('<strong>Filtre actif : </strong>' + window.filterText.trim().substring(0, 140));
    }
    else
    {
      $('#documents_actions .filter_indication').attr('style', 'display: none');
      $('#documents_actions .filter_indication_text').html('');
    }
  }

  function initEventOnPackOrReportRefresh(){
    $("a.do-show-pack").unbind("click");
    $("a.do-show-pack").bind("click",function() {
      if(window.datasLoaderLocked || window.piecesLoaderLocked)
        return false;

      $('#documentslist .content > ul > li').removeClass('activated');
      $(this).parents('li').addClass('activated');

      show_pieces_view();
      window.currentLink = $(this);

      $("#panel1 > .content").html("");
      $("#presPanel1 > .content").html("");

      $(".href_download").val('');
      $(".href_download_zip").val('');
      
      var href_download = $(this).parents('li').find('.action .download').attr('href') || '#';
      var href_zip_download = $(this).parents('li').find('.action .zip_download').attr('href') || '#';

      $(".href_download").val(href_download);
      $(".href_download_zip").val(href_zip_download);

      showPieces(window.currentLink);
      initParameters(window.currentLink);         

      return false;
    });

    $("a.do-show-report").unbind("click");
    $("a.do-show-report").bind("click",function() {
      if(window.datasLoaderLocked || window.preseizuresLoaderLocked)
        return false;

      show_preseizures_view();

      $('#documentslist .content > ul > li').removeClass('activated');
      $(this).parents('li').addClass('activated');

      window.currentLink = $(this);

      $('#panel1 > .header .actiongroup .download').removeAttr('href');
      $('#panel1 > .header .actiongroup .zip_download').removeAttr('href');
      $("#panel1 > .content").html("");
      $("#presPanel1 > .content").html("");

      getPreseizures(window.currentLink, 1, null);

      return false;
    });

    $("a.do-select").unbind("click");
    $("a.do-select").bind("click",function(){ $(this).parents("li").toggleClass("selected"); return false; });

    $(".packsList .pagination a").unbind('click');
    $(".packsList .pagination a").bind('click',function(e) {
      e.preventDefault();

      if(!$(this).parents('li').hasClass('disabled') && !$(this).parents('li').hasClass('active'))
        showPacksOrReports($(this), 'pack');
      return false;
    });

    $(".reportsList .pagination a").unbind('click');
    $(".reportsList .pagination a").bind('click',function(e) {
      e.preventDefault();

      if(!$(this).parents('li').hasClass('disabled') && !$(this).parents('li').hasClass('active'))
        showPacksOrReports($(this), 'report');
      return false;
    });

    $(".scroll_on_top").unbind('click');
    $(".scroll_on_top").bind('click',function(e) { 
      var body = $("html, body");
      body.stop().animate({scrollTop:0}, 500, 'swing', function() {});
    });

    $("a.pack_tag").unbind("click");
    $("a.pack_tag").bind("click",function(e) {
      e.preventDefault();
      get_content_tag('pack');
      return false;
    });

  }

  function show_pieces_view(){
    window.currentView = 'pieces';

    $("#pageslist").fadeIn('slow');
    $("#preseizuresList").hide();
  }

  function show_preseizures_view(){
    window.currentView = 'preseizures';

    $('#presPanel1 .header .actiongroup .selected_items_info').remove();
    $("#preseizuresList #presPanel1").attr("style","min-height:"+$("#documentslist").height()+"px;");
    $("#preseizuresList").fadeIn('slow');
    $("#pageslist").hide();
  }


  // get packs of page given by link
  function showPacksOrReports(link, type='pack') {
    var page = 1;
    var regexp = new RegExp("page=[0-9]+");
    var regexp2 = new RegExp("[0-9]+");
    result = regexp2.exec(regexp.exec(link.attr("href").replace(/per_page=\d/,"")));
    if (result != null)
      page = result[0];

    if(type == 'pack')
      getPacks(page);
    else
      getReports(page);
  }

  // fetch lists of packs
  function getPacks(page = 1, then_reports = false) {
    if(window.datasLoaderLocked)
      return false;

    window.datasLoaderLocked = true;

    $('#documentslist .packsList .content').html('');
    $("#documentslist .packsList h3").text("... lot(s)");
    if(then_reports)
    {
      $('#documentslist .reportsList .content').html('');
      $("#documentslist .reportsList h3").text("... lot(s)");
    }

    var filter = ''
    if(window.currentTargetFilter == 'all')
    {
      filter = window.getParamsFromFilter();
      window.setParamsFilterText();
    }
    setTimeout(function(e){
      var view = $("select[name=document_owner_list]").val();
      var per_page = $("select[name=per_page]").val();

      if (view == 'current_delivery') {
        $('a.delivery').hide();
      } else {
        $('a.delivery').show();
      }

      $("#panel1 .header h3").text('Pieces');
      $("#panel1 > .content").html("");

      $("#presPanel1 .header h3").text('Ecritures comptables')
      $("#presPanel1 > .content").html("")

      var Url = "/account/documents/packs?page="+page+"&view="+view+"&per_page="+per_page+'&'+filter;
      window.currentLink = null;

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
          var list = $("#documentslist .packsList .content");
          list.children("*").remove();
          list.append(data);

          packs_count = $("input[name=packs_count]").val();

          $("#documentslist .packsList h3").text(packs_count + " lot(s)");

          $("#pageslist #panel1").attr("style","min-height:"+$("#documentslist").height()+"px");
          $("#preseizuresList #presPanel1").attr("style","min-height:"+$("#documentslist").height()+"px");

          initEventOnPackOrReportRefresh();
          window.initEventOnHoverOnInformation();

          setTimeout(function(){
            window.datasLoaderLocked = false;
            if(then_reports)
              getReports();
          }, 1000);
        },
        error: function(data){
          logAfterAction();
          $(".alerts").html("<div class='row-fluid'><div class='span12 alert alert-danger'><a class='close' data-dismiss='alert'> × </a><span> Une erreur est survenue et l'administrateur a été prévenu.</span></div></div>");
          setTimeout(function(){
            window.datasLoaderLocked = false;
            if(thenReports)
              getReports();
           }, 1000);
        }
      });
    }, 500);
  }

  //fetch lists of report (operation reports)
  function getReports(page = 1){
    if(window.datasLoaderLocked)
      return false;

    window.datasLoaderLocked = true;
    $('#documentslist .reportsList .content').html('');
    $("#documentslist .reportsList h3").text("... lot(s)");

    var filter = ''
    if(window.currentTargetFilter == 'all')
    {
      filter = window.getParamsFromFilter();
      window.setParamsFilterText();
    }

    var view = $("select[name=document_owner_list]").val();
    var per_page = $("select[name=per_page]").val();

    $("#panel1 .header h3").text('Pieces');
    $("#panel1 > .content").html("");

    $("#presPanel1 .header h3").text('Ecritures comptables');
    $("#presPanel1 > .content").html("")

    var Url = "/account/documents/reports?page="+page+"&view="+view+"&per_page="+per_page+'&'+filter;
    window.currentLink = null;

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
        var list = $("#documentslist .reportsList .content");
        list.children("*").remove();
        list.append(data);

        reports_count = $("input[name=reports_count]").val();
        
        $("#documentslist .reportsList h3").text(reports_count + " lot(s)");

        $("#pageslist #panel1").attr("style","min-height:"+$("#documentslist").height()+"px");
        $("#preseizuresList #presPanel1").attr("style","min-height:"+$("#documentslist").height()+"px");

        initEventOnPackOrReportRefresh();
        window.initEventOnHoverOnInformation();

        setTimeout(function(){ window.datasLoaderLocked = false; }, 1000);
      },
      error: function(data){
        logAfterAction();
        $(".alerts").html("<div class='row-fluid'><div class='span12 alert alert-danger'><a class='close' data-dismiss='alert'> × </a><span> Une erreur est survenue et l'administrateur a été prévenu.</span></div></div>");
        setTimeout(function(){ window.datasLoaderLocked = false; }, 1000);
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
        $("#pagesTaggingDialog .length_alert").html("<div class='alert alert-danger'><a class='close' data-dismiss='alert'> × </a><span>Veuillez sélectionner au moins un document.</span></div>");
      if ($pagesTags.val().length <= 0)
        $("#pagesTaggingDialog .names_alert").html("<div class='alert alert-danger'><a class='close' data-dismiss='alert'> × </a><span>Veuillez indiquer au moins un tag.</span></div>");

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

    $("#pagesTaggingDialog").on("hidden.bs.modal",function() {
      $("#pagesTaggingDialog .length_alert").html("");
      $("#pagesTaggingDialog .names_alert").html("");
      $("#pagesTags").val("");
    });

    $("#pagesTags").change(function() {
      $("#pagesTaggingDialog .names_alert").html("");
    });

    $("#selectionTaggingDialog").on("hidden.bs.modal",function() {
      $("#selectionTaggingDialog .length_alert").html("");
      $("#selectionTaggingDialog .names_alert").html("");
      $("#selectionsTags").val("");
    });

    $("#selectionsTags").change(function() {
      $("#selectionTaggingDialog .names_alert").html("");
    });

    $("#deliverButton").click(function() {
      var pack_ids = $.map($("#documentslist .packsList .content > ul > li.selected"), function(li){ return li.id.split("_")[2] });
      var view = $("select[name=document_owner_list]").val();
      var delivery_type = $("input[name=delivery_type]:checked").val();
      var hsh = { "pack_ids": pack_ids, "view": view, "type": delivery_type };
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
          $(".alerts").html("<div class='row-fluid'><div class='span12 alert alert-danger'><a class='close' data-dismiss='alert'> × </a><span> Erreur interne, l'administrateur a été prévenu.</span></div></div>");
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

    $("#documentsTaggingButton").click(function(e) {
      e.preventDefault();
      var document_ids = $.map($("#documentslist .packsList .content > ul > li.selected"), function(li){ return li.id.split("_")[1] });
      var $documentsTags = $("#documentsTags");

      if (document_ids.length <= 0)
        $("#documentsTaggingDialog .length_alert").html("<div class='alert alert-danger'><a class='close' data-dismiss='alert'> × </a><span>Veuillez sélectionner au moins un document.</span></div>");
      if ($documentsTags.val().length <= 0)
        $("#documentsTaggingDialog .names_alert").html("<div class='alert alert-danger'><a class='close' data-dismiss='alert'> × </a><span>Veuillez indiquer au moins un tag.</span></div>");

      if (document_ids.length > 0 && $documentsTags.val().length > 0) {
        var tags = $documentsTags.val();
        $documentsTags.val("");
        postTags(tags,document_ids,'pack');
        aTags = tags.split(" ");
        $("#documentslist .packsList .content > ul > li.selected").each(function(i,li) {
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

    $("#documentsTaggingDialog").on('hidden.bs.modal',function() {
      $("#documentsTaggingDialog .length_alert").html("");
      $("#documentsTaggingDialog .names_alert").html("");
      $("#documentsTags").val("");
    });

    $("#documentsTags").change(function() {
      $("#documentsTaggingDialog .names_alert").html("");
    });

    $("#shareDialog").on('show.bs.modal',function(){
      var pack_ids = $.map($("#documentslist .packsList .content > ul > li.selected"), function(li){ return li.id.split("_")[2] });
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
      var pack_ids = $.map($("#documentslist .packsList .content > ul > li.selected"), function(li){ return li.id.split("_")[2] });
      if(pack_ids != "")
        window.location = "/account/documents/multi_pack_download?pack_ids=" + pack_ids.join('_')
      else
        $(".alerts").html("<div class='row-fluid'><div class='span12 alert alert-danger'><a class='close' data-dismiss='alert'> × </a><span>Veuillez selectionner au moins un document.</span></div></div>");
    });

    $(".do-selectAll").click(function(e){ e.preventDefault(); $("#documentslist .packsList .content > ul > li").addClass("selected"); });
    $(".do-unselectAll").click(function(e){ e.preventDefault(); $("#documentslist .packsList .content > ul > li").removeClass("selected"); });

    $(".modal-close").click(function(){ $(".modal").modal("hide"); });
    $(".close").click(function(){ $(this).parents("li").remove(); });

    $("#selectionlist .content ul").sortable({
      handle: '.handle'
    });

    $(".view_for").change(function() {
      getPacks(1, true);
    });

    $(".per_page").change(function() {
      getPacks(1, true);
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

    $('#packFilterModal #packFilterForm input').keypress(function (e) {
      if (e.which == 13) {
        e.preventDefault();
        $("#packFilterModal #validatePackFilterModal").click();
        return false;
      }
    });

    $("#packFilterModal #validatePackFilterModal").click(function(e) {
      e.preventDefault();
      $("#packFilterModal").modal('hide');
      if(window.datasLoaderLocked || window.piecesLoaderLocked || window.preseizuresLoaderLocked)
        return false;

      if(window.currentTargetFilter == 'all'){
        getPacks(1, true);
      }
      else if (window.currentLink != null && window.currentLink != undefined){
        var source = (window.currentLink.parents("li").hasClass('report'))? 'report' : 'pack'

        if(source == 'pack')
          showPieces(window.currentLink)
        else
          getPreseizures(window.currentLink, 1, null)
      }
      else{
        alert('Vous devez selectionner un lot pour ce type de filtre!');
      }
    });

    $('#documents_actions #initPackFilter, #packFilterModal #initPackFilterModal').click(function(){
      $("#packFilterModal").modal('hide');
      if(window.datasLoaderLocked || window.piecesLoaderLocked || window.preseizuresLoaderLocked)
        return false;

      $('#packFilterModal #packFilterForm')[0].reset();
      if(window.currentTargetFilter == 'selected' && window.currentLink != null && window.currentLink != undefined){
        var source = (window.currentLink.parents("li").hasClass('report'))? 'report' : 'pack'

        if(source == 'pack')
          showPieces(window.currentLink)
        else
          getPreseizures(window.currentLink, 1, null)
      }
      else{
        getPacks(1, true);
      }
    });

    $('#documentslist .subView #view_packs').click(function(){
      $('#documentslist .subView .tab-nav').removeClass('selected');
      $(this).addClass('selected');

      $('#documentslist .packsList').removeClass('hide');
      $('#documentslist .reportsList').addClass('hide');
    });

    $('#documentslist .subView #view_reports').click(function(){
      $('#documentslist .subView .tab-nav').removeClass('selected');
      $(this).addClass('selected');

      $('#documentslist .packsList').addClass('hide');
      $('#documentslist .reportsList').removeClass('hide');
    });

    $('#packFilterModal #target_filter').on('change', function(){
      var value = $(this).val()

      if(value == 1)
      {
        window.currentTargetFilter = 'selected';
        $('#packFilterForm #by_pack_pack_name').attr('disabled', 'disabled');
        $('#packFilterModal .target_filter .full_search').addClass('hide');
      }
      else
      {
        window.currentTargetFilter = 'all'
        $('#packFilterForm #by_pack_pack_name').removeAttr('disabled');
        $('#packFilterModal .target_filter .full_search').removeClass('hide');
      }
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
        {
          showPieces(window.currentLink, window.piecesPage, null, true);
        }
      }
      else if(window.currentView == 'preseizures')
      {
        diffHeight = $('#lists_preseizures #lists_preseizures_content').outerHeight() - $(window).outerHeight();
        if(sTop >= (diffHeight - 25))
          getPreseizures(window.currentLink, window.preseizuresPage);
      }
      
      if (sTop > 600)
      {
        $('.scroll_on_top').show('slow');
        $('#show_pages .actiongroup, #presPanel1 .actiongroup').addClass('actiongroup-fixed');
      }
      else 
      {
        $('.scroll_on_top').hide('slow');
        $('#show_pages .actiongroup, #presPanel1 .actiongroup').removeClass('actiongroup-fixed');
      }
    });
  }

  //force the color of all icons to dark
  function adjustIconColorDocument() {
    $('.oi-icon').each(function(e) {
      if(!$(this).hasClass('colored')) {
        $(this).css('fill', '#3E2F24');
        $(this).addClass('colored');
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
    window.currentTargetFilter = 'all'
    window.currentLink = null;
    window.preseizuresSelected = [];

    window.datasLoaderLocked = false;
    window.piecesLoaderLocked = false;
    window.preseizuresLoaderLocked = false;

    window.filterText = '';

    _require('/assets/account/documents/pieces_event_handler.js');
    _require('/assets/account/documents/preseizures_event_handler.js');
    
    //View Initializers
    initManager();

    initEventOnPackOrReportRefresh();
    initEventOnPreseizuresRefresh();
    window.initEventOnHoverOnInformation();

    $("#pageslist #panel1").attr("style","min-height:"+$("#documentslist").height()+"px");
    $("#preseizuresList #presPanel1").attr("style","min-height:"+$("#documentslist").height()+"px");

    $("#invoice-show").css("height",(document.body.scrollHeight-50)+"px");
    $("#invoice-show").css("width",(document.body.clientWidth-5)+"px");

    //auto click on link where there is only one pack
    if($('#documentslist .packsList .content ul li').length == 1) {
      setTimeout(function() { $('#documentslist .packsList .content ul li:first').find('.do-show-pack').click() }, 1000 );
    }

    adjustIconColorDocument();
  });

})(jQuery);

(function($) {
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
  }

  // remove page from the selection field
  function removePage(page) {
    var id = page.attr("id").split("_")[1];
    $("#composition_"+id).remove();
  }
  
  // showing all pages of the document given by link
  function showPages(link) {
    var document_id = link.parents("li").attr("id").split("_")[2];
    
    var filtre = $("#filter").val();
    if (filtre != "")
      filtre = "?filtre="+filtre;
    var url = "/account/documents/"+document_id+filtre;
    
    $("#panel2").hide();
    $("#panel1").show();
    getPages(url,link.text());
  }
  
  // show the preview of page given by link
  function showPage(link) {
    $("#panel1").hide();
    $("#panel2").show();
    
    $(".actiongroup.group1").hide();
    $(".actiongroup.group2").show();
    
    $("#pageslist .header h3.all").hide();
    $("#pageslist .header .single").show();
    
    $(".showPage").attr("src",link.attr("href"));
    var li = link.parents("li");
    var id = li.attr("id").split("_")[1];
    var tags = li.children("input[name=tags]").val();
    var name = li.children("input[name=name]").val();
    
    $(".showPage").attr("id",id);
    $("#pageInformation").attr("data-content","Tags : "+tags);
    
    $("#panel2 .header h3").text(name);
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
    page = regexp2.exec(regexp.exec(link.attr("href")))[0];
    getPacks(page);
  }
  
  // fecth all pages of the documents
  function getPages(url,title) {
    $.ajax({
      url: url,
      data: "",
      dataType: "html",
      type: "GET",
      beforeSend: function() {
        logBeforeAction("Traitement en cours");
        $("#panel1 > .content > ul").html("");
      },
      success: function(data){
        logAfterAction();
        $("#panel1 > .content > ul").append(data);
        initEventOnClickOnLinkButton();
        initEventOnHoverOnInformation();
        synchroniseSelected();
        $("#pageslist").attr("style","min-height:"+$("#documentslist").height()+"px");
        var page_number = $("#panel1 > .content > ul > li").length;
        var pagesTitle = $("#panel1 .header h3");
        var sTitle = "";
        if (title)
          sTitle = title + " - " + page_number + " page(s)";
        else
          sTitle = "Résultat : " + page_number + " page(s)";
        pagesTitle.text(sTitle);
      },
      error: function(data){
        logAfterAction();
        $(".alerts").html("<div class='alert alert-error'><a class='close' data-dismiss='alert'> × </a><span> Une erreur est survenue, veuillez réessayer s'il vous plaît.</span></div>");
      }
    });
  }

  // fetch list of packs
  function getPacks(PAGE) {
    var filtre = $("#filter").val();
    if (filtre != "")
      filtre = ";filtre="+filtre;
    var view = $("select[name=document_owner_list]").val();
    var per_page = $("select[name=per_page]").val();
    var page = typeof(PAGE) != 'undefined' ? PAGE : 1;
    
    var Url = "/account/documents/packs?page="+page+";view="+view+";per_page="+per_page+filtre;
    
    $.ajax({
      url: Url,
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
        $("#panel1").show();
        
        packs_count = $("input[name=packs_count]").val();
        $("#documentslist > .header > h3").text(packs_count + " documents");
        
        $("#pageslist").attr("style","min-height:"+$("#documentslist").height()+"px");
        
        initEventOnClickOnLinkButton();
        initEventOnHoverOnInformation();
      },
      error: function(data){
        logAfterAction();
        $(".alerts").html("<div class='alert alert-error'><a class='close' data-dismiss='alert'> × </a><span> Une erreur est survenue, veuillez réessayer s'il vous plaît.</span></div>");
      }
    });
  }
  
  // submit tag
  function postTags(tags,document_ids) {
    var hsh = {"document_ids": document_ids, "tags": tags};
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
      showPages($(this));
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
      showPacks($(this));
      return false;
    });
    
    $("a.do-showPage").unbind('click');
    $("a.do-showPage").bind('click',function() {
      showPage($(this));
      return false;
    });
    
    $("a.do-select").unbind("click");
    $("a.do-select").bind("click",function(){ $(this).parents("li").toggleClass("selected"); });
    
    // archive link handler
    $("a.do-archive").unbind("click");
    $("a.do-archive").bind("click",function() {
      link = $(this);
      var pack_id = link.parents("li").attr("id").split("_")[2];
      $.ajax({
        url: "/account/documents/archive",
        data: hsh = {"pack_id":pack_id},
        dataType: "json",
        type: "POST",
        beforeSend: function() {
          logBeforeAction("Traitement en cours");
        },
        success: function(data) {
          logAfterAction();
          baseurl = window.location.pathname.split('/')[0];
          window.open(baseurl+""+data);
        },
        error: function(e) {
          logAfterAction();
          $(".alerts").html("<div class='alert alert-error'><a class='close' data-dismiss='alert'> × </a><span><span class='label label-important'>erreur</span> : " + e.responseText +" </span></div>");
        }
      });
      return false;
    });
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
    // filter autocompletion
    $("#filter").tokenInput("/account/documents/search.json", {
      theme: "facebook",
      hintText: "Tapez au moins 2 caractères pour commencer la recherche.",
      noResultsText: "Aucun résultat",
      searchingText: "Recherche en cours...",
      tokenDelimiter: ":_:",
      tokenValue: "name",
      propertyToSearch: "name",
      preventDuplicates: false,
      minChars: 2,
      resultsFormatter: function(item) {
        var type  = "";
        if (item.id == 1)
          type = " - tag";
        else if (item.id == 2)
          type = " - inconnu";
        return "<li>" + item.name + "<span class='filter-result-type'>"+type+"</span></li>";
      },
      tokenFormatter: function(item) {  return "<li>" + item.name + "</li>" },
      onAdd: function (item) {
        $("#panel1 .header h3").text("");
        $("#panel1 > .content > ul").html("");
        getPacks();
      },
      onDelete: function (item) {
        $("#panel1 .header h3").text("");
        $("#panel1 > .content > ul").html("");
        getPacks();
      }
    });
  
    // payement mode management by AJAX
    $("input[type=radio]").click(function() {
      var request_value = 0;
      if ($(this).val() == "false")
        request_value = 1;
      else
        request_value = 2;
      hsh = {mode: request_value};
      $.ajax({
        url: "/account/payment/mode",
        data: hsh,
        dataType: "json",
        type: "POST",
        beforeSend: function() {
        },
        success: function(data){
          if (data == "1"){
            $(".alerts").html("<div class='alert alert-success'><a class='close' data-dismiss='alert'> × </a><span> Vos réglements seront maintenant débités de votre compte prépayé.</span></div>");
          } else if (data == "2") {
            $(".alerts").html("<div class='alert alert-success'><a class='close' data-dismiss='alert'> × </a><span> Vos réglements seront maintenant prélevés sur votre compte bancaire.</span></div>");
          } else if (data == "3") {
            $(".alerts").html("<div class='alert alert-info'><a class='close' data-dismiss='alert'> × </a><span> Vous n'avez pas encore configuré votre prélèvement.</span></div>");
            $("#prlv").attr('checked', false);
            $("#pp").attr('checked', true);
          } else {
            $(".alerts").html("<div class='alert alert-error'><a class='close' data-dismiss='alert'> × </a><span> Une erreur est survenue, veuillez réessayer s'il vous plaît.</span></div>");
          }
        }
      });
    });
    
    $("#sharingButton").click(function() {
      var pack_ids = $.map($("#documentslist > .content > ul > li.selected.scanned, #documentslist > .content > ul > li.selected.sharing"), function(li){ return li.id.split("_")[2] });
      var $names = $("#sharing_names");
      
      if (pack_ids.length <= 0)
        $("#sharingDialog .sharing.length_alert").html("<div class='alert alert-error'><a class='close' data-dismiss='alert'> × </a><span>Veuillez sélectionner au moins un de vos document.</span></div>");
      if ($names.val().length <= 0)
        $("#sharingDialog .sharing.names_alert").html("<div class='alert alert-error'><a class='close' data-dismiss='alert'> × </a><span>Veuillez indiquer au moins un utilisateur.</span></div>");
      
      if (pack_ids.length > 0 && $names.val().length > 0) {
        $("#sharingDialog").modal("hide");
        var hsh = {"pack_ids": pack_ids, "email": $names.val()};
        $names.val("");
        $.ajax({
          url: "/account/documents/sharings",
          data: hsh,
          dataType: "json",
          type: "POST",
          beforeSend: function() {
            logBeforeAction("Traitement en cours");
          },
          success: function(data){
            logAfterAction();
            current_page = parseInt($("#documentslist .pagination em").text());
            getPacks(current_page);
          }
        });
      }
      return false;
    });
    
    $("#sharingDialog").on("hidden",function() {
      $("#sharingDialog .length_alert").html("");
      $("#sharingDialog .names_alert").html("");
      $("#sharing_names").val("");
    });
    
    $("#sharing_names").change(function() {
      $("#sharingDialog .names_alert").html("");
    });
    
    $("#unsharingButton").click(function(){
      var pack_ids = $.map($("#documentslist > .content > ul > li.selected.shared"), function(li){ return li.id.split("_")[2] });
      if (pack_ids.length > 0) {
        $("#sharingDialog").modal("hide");
        $("#sharing_names").val("");
        var hsh = {"pack_ids": pack_ids};
        $.ajax({
          url: "/account/documents/sharings/destroy_multiple",
          data: hsh,
          dataType: "json",
          type: "POST",
          beforeSend: function() {
            logBeforeAction("Traitement en cours");
          },
          success: function(data){
            logAfterAction();
            current_page = parseInt($("#documentslist .pagination em").text());
            getPacks(current_page);
          }
        });
      } else {
        $("#sharingDialog .unsharing.length_alert").html("<div class='alert alert-error'><a class='close' data-dismiss='alert'> × </a><span>Veuillez sélectionner au moins un document, qui vous a été partagé.</span></div>");
      }
      return false;
    });
    
    $("#documentsTaggingButton").click(function() {
      var document_ids = $.map($("#documentslist > .content > ul > li.selected"), function(li){ return li.id.split("_")[1] });
      var $documentsTags = $("#documentsTags");
      
      if (document_ids.length <= 0)
        $("#documentsTaggingDialog .length_alert").html("<div class='alert alert-error'><a class='close' data-dismiss='alert'> × </a><span>Veuillez sélectionner au moins un document.</span></div>");
      if ($documentsTags.val().length <= 0)
        $("#documentsTaggingDialog .names_alert").html("<div class='alert alert-error'><a class='close' data-dismiss='alert'> × </a><span>Veuillez indiquer au moins un tag.</span></div>");
        
      if (document_ids.length > 0 && $documentsTags.val().length > 0) {
        var tags = $documentsTags.val();
        $documentsTags.val("");
        postTags(tags,document_ids);
        aTags = tags.split(" ");
        $("#documentslist > .content > ul > li.selected").each(function(i,li){
          var link = $(li).children(".action").children(".do-popover");
          var other_content = link.attr("data-content").split("Tags :")[0];
          var oTags = link.attr("data-content").split("Tags :")[1];
          
          for ( var i=aTags.length-1; i>=0; --i ){
            if (aTags[i].match("-")) {
              var reg = new RegExp(aTags[i].replace("-",""),"g");
              oTags = oTags.replace(reg,"");
            } else {
              if (!oTags.match(aTags[i])) {
                oTags = oTags + " " + aTags[i];
              }
            }
          }
          link.attr("data-content",other_content + "Tags : " + oTags);
        });
        $("#documentsTaggingDialog").modal('hide');
      }
      return false;
    });
    
    $("#documentsTaggingDialog").on("hidden",function() {
      $("#documentsTaggingDialog .length_alert").html("");
      $("#documentsTaggingDialog .names_alert").html("");
      $("#documentsTags").val("");
    });
    
    $("#documentsTags").change(function() {
      $("#documentsTaggingDialog .names_alert").html("");
    });
    
    $("#pagesTaggingButton").click(function() {
      var document_ids = $.map($("#panel1 > .content > ul > li.selected"), function(li){ return li.id.split("_")[1] });
      var $pagesTags = $("#pagesTags");
      
      if (document_ids.length <= 0)
        $("#pagesTaggingDialog .length_alert").html("<div class='alert alert-error'><a class='close' data-dismiss='alert'> × </a><span>Veuillez sélectionner au moins un document.</span></div>");
      if ($pagesTags.val().length <= 0)
        $("#pagesTaggingDialog .names_alert").html("<div class='alert alert-error'><a class='close' data-dismiss='alert'> × </a><span>Veuillez indiquer au moins un tag.</span></div>");
      
      if (document_ids.length > 0 && $pagesTags.val().length > 0) {
        postTags($pagesTags.val(),document_ids);
        $pagesTags.val("");
        $("#pagesTaggingDialog").modal("hide");
      }
      return false;
    });
    
    $("#pagesTaggingDialog").on("hidden",function() {
      $("#pagesTaggingDialog .length_alert").html("");
      $("#pagesTaggingDialog .names_alert").html("");
      $("#pagesTags").val("");
    });
    
    $("#pagesTags").change(function() {
      $("#pagesTaggingDialog .names_alert").html("");
    });
    
    $("#selectionsTaggingButton").click(function(){
      var document_ids = $.map($("#selectionlist > .content > ul > li"), function(li){ return li.id.split("_")[1] });
      var $selectionsTags = $("#selectionsTags");
      
      if (document_ids.length <= 0)
        $("#selectionTaggingDialog .length_alert").html("<div class='alert alert-error'><a class='close' data-dismiss='alert'> × </a><span>Veuillez sélectionner au moins un document.</span></div>");
      if ($selectionsTags.val().length <= 0)
        $("#selectionTaggingDialog .names_alert").html("<div class='alert alert-error'><a class='close' data-dismiss='alert'> × </a><span>Veuillez indiquer au moins un tag.</span></div>");

      if (document_ids.length > 0 && $selectionsTags.val().length > 0) {
        postTags($selectionsTags.val(),document_ids);
        $selectionsTags.val("");
        $("#selectionTaggingDialog").modal("hide");
      }
      return false;
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
    
    $("#compositionDialog").on("hidden",function() {
      $("#compositionDialog .length_alert").html("");
      $("#compositionDialog .names_alert").html("");
      $("#composition_name").val("");
    });
    
    $("#composition_name").change(function() {
      $("#compositionDialog .names_alert").html("");
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
    
    $("a.do-selectSinglePage").click(function(){
      var id = "#document_" + $(".showPage").attr("id");
      var li = $(id);
      li.addClass("selected");
      addPage(li);
    });
    $("a.do-unselectSinglePage").click(function(){
      var id = "#document_" + $(".showPage").attr("id");
      var li = $(id);
      li.removeClass("selected");
      removePage(li);
    });
    
    $(".modal-close").click(function(){ $(".modal").modal("hide"); });
    $(".close").click(function(){ $(this).parents("li").remove(); });
    
    // selection event handler
    $(".do-selectAll").click(function(){ $("#documentslist > .content > ul > li").addClass("selected"); });
    $(".do-unselectAll").click(function(){ $("#documentslist > .content > ul > li").removeClass("selected"); });
    
    $("#pageslist").attr("style","min-height:"+$("#documentslist").height()+"px");
    
    $(".do-selectAllPages").click(function(){
      $("#panel1 > .content > ul > li").each(function(index,li){
        if (!$(li).hasClass("selected")) {
          $(li).addClass("selected");
          addPage($(li));
        }
      });
    });
    $(".do-unselectAllPages").click(function(){
      $("#panel1 > .content > ul > li").removeClass("selected");
      $("#panel1 > .content > ul > li").each(function(index,li){
        removePage($(li));
      });
    });
    
    $("a.do-nextPage").click(function(){
      var id = $(".showPage").attr("id");
      var li = $("#document_"+id);
      var link = li.next().children(".do-showPage");
      if (link.length > 0)
        showPage(link);
    });
    $("a.do-prevPage").click(function(){
      var id = $(".showPage").attr("id");
      var li = $("#document_"+id);
      var link = li.prev().children(".do-showPage")
      if (link.length > 0)
        showPage(link);
    });
    
    
    $(".backToPanel1").click(function(){
      $("#panel2").hide();
      $("#panel1").show();
      
      $(".actiongroup.group1").show();
      $(".actiongroup.group2").hide();
    });
    
    $("a.removeAllSelection").click(function() {
      synchroniseRemovedSelection();
      $("#selectionlist .content ul").html("");
    });
    
    $("#selectionlist .content ul").sortable({
      handle: '.handle'
    });
  });
  
})(jQuery);
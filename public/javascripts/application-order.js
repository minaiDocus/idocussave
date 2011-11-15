var CompositionVisible = true;
var DocumentsVisible = true;
var PagesVisible = true;
var DocumentName = "";

function setVisibility(){
  //Tags
  if ($("input[name=tags].visibility").is(':checked'))
    $(".document_tags").show();
  else
    $(".document_tags").hide();
  //Selection
  if (CompositionVisible){
    $("li.document.page.composition").show();
    $("a.do-showSelection").children("span").text("Cacher");
  }else{
    $("li.document.page.composition").hide();
    $("a.do-showSelection").children("span").text("Afficher");
  }
  nombre = 0;
  $("ul.pageslist.composition li.document").each(function(index){
    nombre++;
  });
  $(".titlebar.composition_title h1").html("<span>sélection</span><span class='filter-result'> - "+nombre+" page(s)</span>");
  //Documents
  $("li.document.group").show();
  
  value = $("#document_owner_list").val();
  if(value == "self"){
    $("li.document.group.shared").hide();
  }else if(value != "all"){
    $("li.document.group").hide();
    $("li.document.group."+value).show();
  }
  
  nombre = $("input[name=packs_count]").val();
  $(".titlebar.orders_scanned_title h1").html("<span>documents</span><span class='filter-result'> - "+nombre+" résultat(s)</span>");
  
  if (!DocumentsVisible){
    $("li.document.group").hide();
    $("a.do-showDocuments").children("span").text("Afficher");
  }else{
    $("a.do-showDocuments").children("span").text("Cacher");
  }
  //Pages
  if (PagesVisible){
    $("li.document.page.alone").show();
    $("a.do-showPages").children("span").text("Cacher");
  }else{
    $("li.document.page.alone").hide();
    $("a.do-showPages").children("span").text("Afficher");
  }
  nombre = 0;
  $("ul.pageslist.all li.document.page,ul.pageslist.find_result li.document.page").each(function(index){
    nombre++;
  });
  PagesTitle = "<span>pages "+DocumentName+"</span><span class='filter-result'>- "+nombre+" page(s)</span>";
  $(".titlebar.pages_title h1").html(PagesTitle);
  
  if ($("ul.pageslist.composition li.document").length > 0)
    activateCompositionButton();
  else
    deactivateCompositionButton();
  
  $(".pagesbrowser").jScrollPane({
    scrollbarWidth : 10,
    scrollbarMargin : 5,
    wheelSpeed : 18,
    showArrows : false,
    arrowSize : 0,
    animateTo : false,
    dragMinHeight : 1,
    dragMaxHeight : 99999,
    animateInterval : 100,
    animateStep: 3,
    maintainPosition: true,
    scrollbarOnLeft: false,
    reinitialiseOnImageLoad: false
  });
}

function getDocument(REF,URL){
  var TYPE = REF.hasClass("document")? 1 : 2;
  $.ajax({
    url: URL,
    data: "",
    dataType: "html",
    type: "GET",
    beforeSend: function() {
      logBeforeAction("Chargement du document");
      if (TYPE == 1)
        DocumentName = "de "+REF.children(".foot").children("span").text()+" ";
      $(".titlebar.pages_title h1").html("<span>Pages "+DocumentName+"</span>");
    },
    success: function(data){
      logAfterAction();
      if (TYPE == 1){
        $("ul.pageslist.all").html("");
        $("ul.pageslist.find_result").html("");
        $("ul.pageslist.all").append(data);
      }else{
        $("ul.pageslist.all").html("");
        $("ul.pageslist.find_result").html("");
        $("ul.pageslist.find_result").append(data);
        DocumentName = "";
      }
      setVisibility();
      $("li.document.composition").removeClass("selected");
      setSameDocumentSelected();
      
      doLive();
    }
  });
  return false;
}

function getScans(PAGE){
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
      logBeforeAction("Chargement des documents");
    },
    success: function(data) {
      logAfterAction();
      var list = $("ul.documentslist");
      list.before(data);
      list.next(".pagination").remove();
      list.remove();
      setVisibility();
      doLive();
    }
  });
}

function activateSharingButton(){
  $("a.do-openNewSharingDialog").removeClass("inactive");
}

function deactivateSharingButton(){
  $("a.do-openNewSharingDialog").addClass("inactive");
}

function activateDocumentsTaggingButton(){
  $("a.do-openNewDocumentsTaggingDialog").removeClass("inactive");
}

function deactivateDocumentsTaggingButton(){
  $("a.do-openNewDocumentsTaggingDialog").addClass("inactive");
}

function activatePagesTaggingButton(){
  $("a.do-openNewPagesTaggingDialog").removeClass("inactive");
}

function deactivatePagesTaggingButton(){
  $("a.do-openNewPagesTaggingDialog").addClass("inactive");
}

function activateCompositionButton(){
  $("a.do-openNewCompositionDialog").removeClass("inactive");
}

function deactivateCompositionButton(){
  $("a.do-openNewCompositionDialog").addClass("inactive");
}

function activateButton(){
  activateSharingButton();
  activateDocumentsTaggingButton();
}

function deactivateButton(){
  deactivateSharingButton();
  deactivateDocumentsTaggingButton();
}

function setSamePageSelected(is_composition,li){
  if(is_composition){
    $("li.document.composition").each(function(index){
      if (li.attr('id').split('_')[2] == $(this).attr('id').split('_')[2]){
        li.addClass("selected");
        $(this).addClass("selected");
      }
    });
  }else{
    $("li.document.page.alone").each(function(index){
      if (li.attr('id').split('_')[2] == $(this).attr('id').split('_')[2]){
        li.addClass("selected");
        $(this).addClass("selected");
      }
    });
  }
}

function setSamePageDeselected(is_composition,li){
  if(is_composition){
    $("li.document.composition").each(function(index){
      if (li.attr('id').split('_')[2] == $(this).attr('id').split('_')[2]){
        li.removeClass("selected");
        $(this).remove();
      }
    });
  }else{
    $("li.document.page.alone").each(function(index){
      if (li.attr('id').split('_')[2] == $(this).attr('id').split('_')[2]){
        $(this).removeClass("selected");
      }
    });
  }
}

function setSameDocumentSelected(){
  $("li.document.page.alone").each(function(index){
    setSamePageSelected(true,$(this));
  });
}

function copyDocument(document){
  document.addClass("selected");
  clone = document.clone();
  clone.appendTo("ul.pageslist.composition");
  clone.attr("id",clone.attr("id")+"_composition");
  clone.removeClass("alone");
  clone.children("a.zoom").removeClass("zgallery2").addClass("zgallery3");
  clone.addClass("composition selected");
  $(".composition .toolbar .selector").html("<a class='delete do-deleteDocumentFromComposition' href='#' ></a>");
  $("a.delete.do-deleteDocumentFromComposition").click(function(){
    link = $(this);
    li = link.parents("li.document");
    setSamePageDeselected(false,li);
    li.remove();
    
    return false;
  });
  run_zoombox();
  run_tooltip();
}

function run_zoombox(){
  $("a.zoom").zoombox({
    overflow: true
  });
}

function run_tooltip(){
  $("a[title]").tooltip({
    position:'top right',
    bounce: true,
    effect: 'slide'
  }).dynamic({
    top: {
      direction: 'up',
      bounce: true,
      effect: 'slide'
    },
    bottom: {
      direction: 'down',
      bounce: true,
      effect: 'slide'
    },
    left: {
      direction: 'left',
      bounce: true,
      effect: 'slide'
    },
    right: {
      direction: 'right',
      bounce: true,
      effect: 'slide'
    }
  });
}

function doLive(){
  run_zoombox();
  run_tooltip();
  $("a.do-show").click(function(){
    link = $(this);
    li = link.parents("li.document");
    var order_id = _.map(li, function(node){ return node.id.split("_")[1] });
    var url = "/account/documents/"+order_id;
    getDocument(li,url);
    return false;
  });
  $("a.do-select").click(function(){
    link = $(this);
    li = link.parents("li.document.group");
    li.toggleClass("selected");
    if (li.hasClass("selected")){
      if(!li.hasClass("shared"))
        activateButton();
      else
        activateDocumentsTaggingButton();
    }
    else{
      var desactivate = true;
      $("li.document.group").each(function(index){
        if($(this).hasClass("selected"))
          desactivate = false;
      });
      if(desactivate)
        deactivateButton();
    }
    return false;
  });
  $("a.growl-info").click(function(){
    info = $(this).parents("li.document.group").children(".growl-info").html();
    $.jGrowl(info, {
      sticky: true,
      position: "bottom-right"
    });
    $("a.remote-delete").live("click",function(){
      $.post(this.href,{ _method: 'delete' },function(data){this.remove();},"json");
      return false;
    });
    return false;
  });
  $("a.do-selectPage").click(function(){
    link = $(this);
    li = link.parents("li.document");
    li.toggleClass("selected");
    if (li.hasClass("selected")){
      copyDocument(li);
      activateCompositionButton();
      activatePagesTaggingButton();
    }else{
      setSamePageDeselected(true,li);
      var desactivate = true;
      $("li.document.page.alone").each(function(index){
        if($(this).hasClass("selected"))
          desactivate = false;
      });
      if(desactivate)
        deactivatePagesTaggingButton();
    }
    
    setVisibility();
    
    return false;
  });
  $(".pagination a").click(function(){
    var page = 1;
    var regexp = new RegExp("page=[0-9]+");
    var regexp2 = new RegExp("[0-9]+");
    page = regexp2.exec(regexp.exec($(this).attr("href")));
    getScans(page);
    
    return false;
  });
  $("a.delete").click(function(){
    url = $(this).attr("href");
    hsh = "";
    spinner_id = $(this).next().attr("id");
    $.ajax({
      url: url,
      data: hsh,
      dataType: "json",
      type: "DELETE",
      beforeSend: function() {
      },
      success: function(data){
        $("tr#"+$(this).attr('id')).remove();
      }
    });
    return false;
  });
}

$(document).ready(function () {
  setVisibility();
  doLive();
  
  $("select[name=document_owner_list]").change(function(){
    getScans();
  });
  
  $("select[name=per_page]").change(function(){
    getScans();
  });

  $("a.order_comming_soon").click(function(){
    $.jGrowl("Commande en ligne bientôt disponible", {
      sticky: true,
      position: "bottom-right"
    });
    return false;
  });
  
  $("a.do-growlLegend").click(function(){
    $.jGrowl("<span class='order-paid'>document.pdf</span> : Commande en cours de traitement<br /><br /><span class='order-scanned'>document.pdf</span> : Mon document<br /><br /><span class='order-sharing'>document.pdf</span> : Mon document que je partage<br /><br /><span class='order-shared'>document.pdf</span> : Document partagé par un autre utilisateur",{
      sticky: true,
      position: "top-right"
    });
    return false;
  });
  
  $("#filter").tokenInput("/account/documents/search.json", {
    theme: "facebook",
    hintText: "Tapez un mot à rechercher",
    noResultsText: "Aucun résultat",
    searchingText: "Recherche en cours...",
    tokenDelimiter: ":_:",
    tokenValue: "name",
    preventDuplicates: true,
    resultsFormatter: function(item) { return "<li><p class='" + item.id + "'>" + item.name + "</p></li>" },
    tokenFormatter: function(item) {  return "<li><p class='" + item.id + "'>" + item.name + "</p></li>" },
    onAdd: function (item) {
      var value = $(this).val();
      var url = "/account/documents/find?having="+value;
      getDocument(this,url);
      getScans();
    },
    onDelete: function (item) {
      if($("#filter").val() != ""){
        var value = $(this).val();
        var url = "/account/documents/find?having="+value;
        getDocument(this,url);
      }else{
        $("ul.pageslist.all").html("");
        $("ul.pageslist.find_result").html("");
        setVisibility();
      }
      getScans();
    }
  });
 
  $("a.do-showDocuments").click(function(){
    if(DocumentsVisible)
      DocumentsVisible = false;
    else
      DocumentsVisible = true;
    setVisibility();
    return false;
  });
  
  $("a.do-showPages").click(function(){
    if(PagesVisible)
      PagesVisible = false;
    else
      PagesVisible = true;
    setVisibility();
    return false;
  });
  
  $("a.do-showSelection").click(function(){
    if(CompositionVisible)
      CompositionVisible = false;
    else
      CompositionVisible = true;
    setVisibility();
    return false;
  });
  
  $("a.do-selectAllVisible").click(function(){
    $("li.document.scanned:visible,li.document.sharing:visible,li.document.shared:visible").toggleClass("selected", true);
    activateButton();
    return false;
  });
  
  $("a.do-deselectAllVisible").click(function(){
    $("li.document.scanned:visible,li.document.sharing:visible,li.document.shared:visible").toggleClass("selected", false);
    deactivateButton();
    return false;
  });
  
  $("a.do-selectAllPage").click(function(){
    $("li.document.page.alone").each(function(index){
      if(!$(this).hasClass("selected"))
        copyDocument($(this));
    });
    $("a.do-openNewPagesTaggingDialog").removeClass("inactive");
    return false;
  });
  
  $("a.do-deselectAllPage").click(function(){
    $("li.document.page.alone").each(function(index){
      if($(this).hasClass("selected"))
        setSamePageDeselected(true,$(this));
    });
    $("a.do-openNewPagesTaggingDialog").addClass("inactive");
    return false;
  });
  
  $("input.visibility").change(function(){
    setVisibility();
  });
  
  $("a.delete.do-deleteDocumentFromComposition").click(function(){
    link = $(this);
    li = link.parents("li.document");
    setSamePageDeselected(false,li);
    li.remove();
    setVisibility();
    return false;
  });
  
  $("a.do-openNewCompositionDialog").click(function(){
    if (!($(this).hasClass("inactive"))) {
      $(".newCompositionDialog").dialog({
        modal:true,
        title:"Création d'une composition",
        buttons: { "Valider": function() {
          var ary = $(".pageslist.composition").sortable('toArray');
          var document_ids = _.map(ary, function(str){ return str.split("_")[2] });
          var hsh = {"composition[document_ids]": document_ids, "composition[name]": $("#composition_name").val()};
          $.ajax({
            url: "/account/compositions",
            data: hsh,
            dataType: "json",
            type: "POST",
            beforeSend: function() {
              $("#new_composition_spinner").removeClass("hide", false);
            },
            success: function(data){
              $("#new_composition_spinner").addClass("hide", true);
              baseurl = window.location.pathname.split('/')[0];
              window.open(baseurl+""+data);
            }
          });
          }
        }
      });
    }
    return false;
  });
  
  $("a.do-openNewSharingDialog").click(function(){
    if (!($(this).hasClass("inactive"))) {
      $(".newSharingDialog").dialog({
        modal:true,
        title:"Création d'un nouveau partage",
        buttons: { "Valider": function() {
          var pack_ids = _.map($("li.document.group.scanned.selected,li.document.group.sharing.selected"), function(node){ return node.id.split("_")[1] });
          var hsh = {"pack_ids": pack_ids, "email": $("#sharing_name").val()};
          $.ajax({
            url: "/account/documents/share",
            data: hsh,
            dataType: "json",
            type: "POST",
            beforeSend: function() {
              $("#new_sharing_spinner").removeClass("hide", false);
            },
            success: function(data){
              $("#new_sharing_spinner").addClass("hide", true);
              location.reload();
            }
          });
          }
        }
      });
    }
    return false;
  });
  
  $("a.do-openNewPagesTaggingDialog").click(function(){
    if (!($(this).hasClass("inactive"))) {
      $(".newTaggingDialog").dialog({
        modal:true,
        title:"Edition d'un tag de pages",
        buttons: { "Valider": function() {
          var document_ids = _.map($("li.document.page.alone.selected"), function(node){ return node.id.split("_")[2] });
          var hsh = {"document_ids": document_ids, "tags": $("#tags_name").val()};
          $.ajax({
            url: "/account/documents/update_tag",
            data: hsh,
            dataType: "json",
            type: "POST",
            beforeSend: function() {
              $("#new_tagging_spinner").removeClass("hide", false);
            },
            success: function(data){
              $("#new_tagging_spinner").addClass("hide", true);
              location.reload();
            }
          });
          }
        }
      });
    }
    return false;
  });
  
  $("a.do-openNewDocumentsTaggingDialog").click(function(){
    if (!($(this).hasClass("inactive"))) {
      $(".newTaggingDialog").dialog({
        modal:true,
        title:"Edition d'un tag de document",
        buttons: { "Valider": function() {
          var document_ids = _.map($("li.document.group.selected"), function(node){ return node.id.split("_")[2] });
          var hsh = {"document_ids": document_ids, "tags": $("#tags_name").val()};
          $.ajax({
            url: "/account/documents/update_tag",
            data: hsh,
            dataType: "json",
            type: "POST",
            beforeSend: function() {
              $("#new_tagging_spinner").removeClass("hide", false);
            },
            success: function(data){
              $("#new_tagging_spinner").addClass("hide", true);
              location.reload();
            }
          });
          }
        }
      });
    }
    return false;
  });
  
  $(".pageslist.all").sortable({
    handle: '.handle',
    update: function (event, ui) {
      var ary = $(this).sortable('toArray');
      var document_ids = _.map(ary, function(str){ return str.split("_")[2] });
      hsh = {document_ids: document_ids};
      $.ajax({
        url: "/account/documents/reorder",
        data: hsh,
        dataType: "json",
        type: "POST",
        beforeSend: function() {
          logBeforeAction("Réordonnancement en cours");
        },
        success: function(data){
          logAfterAction();
        }
      });
    }
  });
  
  $(".pageslist.composition").sortable({
    handle: '.handle'
  });
});
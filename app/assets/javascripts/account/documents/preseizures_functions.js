// fecth all preseizures of the pack
function getPreseizures(link, page=1, by_piece=null, then_pieces=false){
  if(page < 1 || window.preseizuresLoaderLocked)
    return false

  window.preseizuresLoaderLocked = true;

  var document_id = link.parents("li").attr("id").split("_")[2];
  var source = (link.parents("li").hasClass('report'))? 'report' : 'pack'
  var document_name = link.text();

  if(by_piece !== null)
  {
    var filter = "&piece_id="+by_piece
  }
  else
  {
    var filter = '&'+window.getParamsFromFilter();
    window.setParamsFilterText();
  }

  var url = "/account/documents/"+document_id+"?source="+source+"&fetch=preseizures&page="+page+filter;

  $.ajax({
    url: encodeURI(url),
    data: "",
    dataType: "html",
    type: "GET",
    beforeSend: function() {
      window.preseizuresPage = page + 1;

      logBeforeAction("Traitement en cours");
      $("#presPanel1 .header h3").text(document_name);
    },
    success: function(data){
      data = data.trim();

      logAfterAction();

      if(page == 1)
      {
        if(data == 'none')
        {
          data = 'Aucun résultat';
          window.preseizuresPage = -1;
        }

        $("#presPanel1 > .content").html(data);
        $('#presPanel1 #show_preseizures h4').text($('#presPanel1 #show_preseizures .total_preseizures_count').text() + ' écriture(s) comptable(s)');

        window.preseizuresSelected = [];
        $('#presPanel1 .header .actiongroup .do-deliverAllPreseizure').attr('style', '');
        $('#presPanel1 .header .actiongroup .do-exportSelectedPreseizures').attr('style', '');

        var software_used = $('#show_preseizures .software_used').text() || '';
        var need_delivery = $('#show_preseizures .need_delivery').text() || 'no';

        if(by_piece === null)
          $('#show_preseizures .showALLPreseizures').addClass('hide');
        else
          $('#show_preseizures .showALLPreseizures').removeClass('hide');

        $('#presPanel1 .header .actiongroup .do-editSelectedPreseizures').addClass('hide');
        $('#presPanel1 .header .actiongroup .do-deliverAllPreseizure').remove();
        if(software_used != '' && need_delivery != 'no')
          $('#presPanel1 .header .actiongroup').prepend('<a href="#" title="Livraison écriture comptable ('+software_used+')" class="do-deliverAllPreseizure do-tooltip"><i class="icon-refresh" /></a>');
      }
      else if(data != 'none' && page > 1)
      {
        var parser = new DOMParser();
        var htmlDoc = parser.parseFromString(data, 'text/html');
        $("#presPanel1 #lists_preseizures_content").append($(htmlDoc).find('#show_preseizures #lists_preseizures_content').html());
      }
      else
      {
        window.preseizuresPage = -1;
      }

      $("#presPanel1 > .content #show_preseizures .preseizure:not(:visible)").fadeIn(1500);

      //calculate height of preseizures content (needed when not visible)
      var lists_preseizures_height = Math.ceil($(window).outerHeight() / 1.5);

      //set Approximative height of lists content when not visible
      var elem_height = 132 //Approximative height of preseizure element
      var elem_count = $('#lists_preseizures_content .preseizure').length;

      var lists_preseizures_content_height = elem_count*elem_height //height approximative

      //Fetch data until a scroll is present
      if(lists_preseizures_height >= lists_preseizures_content_height && window.preseizuresPage > 0)
      { 
        window.preseizuresLoaderLocked = false;
        setTimeout(getPreseizures(window.currentLink, window.preseizuresPage, by_piece), 1000);
      }
      else
      {
        initEventOnPreseizuresRefresh();
        window.initEventOnHoverOnInformation();
        window.handleView();
      }

      //auto open details
      setTimeout(function() {
        $('#presPanel1 #lists_preseizures_content .preseizure').each(function(e){
          if( !$(this).find('.content_details').is(':visible') )
            $(this).find('.preseizure_label .tip_details').click();
        });
      }, 1000);

      setTimeout(function(){
        window.preseizuresLoaderLocked = false;
        if(then_pieces)
          showPieces(window.currentLink, 1);
      }, 1000);
    },
    error: function(data){
      logAfterAction();
      $(".alerts").html("<div class='row-fluid'><div class='span12 alert alert-error'><a class='close' data-dismiss='alert'> × </a><span> Une erreur est survenue et l'administrateur a été prévenu.</span></div></div>");
      setTimeout(function(){
        window.preseizuresLoaderLocked = false;
        if(then_pieces)
          showPieces(window.currentLink, 1);
      }, 1000);
    }
  });
}

//refresh the edited or selected preseizures (param ids must be an array)
function refreshPreseizures(ids){
  if(window.preseizuresLoaderLocked)
    return false;

  var document_id = window.currentLink.parents("li").attr("id").split("_")[2];
  var source = (window.currentLink.parents("li").hasClass('report'))? 'report' : 'pack';
  var url = "/account/documents/"+document_id+"?source="+source+"&fetch=preseizures&page=1";

  ids.forEach(function(id) {
    var elem = $(".preseizure#"+id);
    url += "&preseizure_ids="+id;

    $.ajax({
      url: url,
      data: '',
      dataType: "html",
      type: "GET",
      beforeSend: function() {
        logBeforeAction("Traitement en cours");
        window.preseizuresLoaderLocked = true;
      },
      success: function(data){
        logAfterAction();
        data = data.trim();

        var parser = new DOMParser();
        var htmlDoc = parser.parseFromString(data, 'text/html');

        elem.html($(htmlDoc).find('#show_preseizures #lists_preseizures_content .preseizure#'+id).html());

        initEventOnPreseizuresRefresh();
        window.initEventOnHoverOnInformation();

        //auto open details
        setTimeout(function() {
          $('#presPanel1 #lists_preseizures_content .preseizure').each(function(e){
            if( !$(this).find('.content_details').is(':visible') )
              $(this).find('.preseizure_label .tip_details').click();
          });
        }, 1000);

        setTimeout( function(){ window.preseizuresLoaderLocked = false; }, 1000 );
      },
      error: function(data){
        logAfterAction();
        setTimeout( function(){ window.preseizuresLoaderLocked = false; }, 1000 );
      }
    });
  });
}

function getPreseizureAccount(id, force=false){
  var elem = $(".preseizure#"+id+" > .content_details");
  var exist = (elem.html() != '' && elem.html() != null && elem.html() != undefined) ? true : false;

  if(!force)
  {
    if(elem.is(":visible"))
      elem.slideUp('fast')
    else
      elem.slideDown('fast')
  }

  if(!exist || force)
  {
    $.ajax({
      url: '/account/documents/preseizure_account/'+id,
      data: '',
      dataType: "html",
      type: "GET",
      beforeSend: function() {
        logBeforeAction("Traitement en cours");
        elem.html('<div class="feedback active"><span class="out">Chargement en cours ...</span></div>');
        elem.slideDown('fast')
      },
      success: function(data){
        logAfterAction();
        elem.html(data);

        initEventOnPreseizuresAccountRefresh();
      },
      error: function(data){
        logAfterAction();
        elem.html('');
        $(".alerts").html("<div class='row-fluid'><div class='span12 alert alert-error'><a class='close' data-dismiss='alert'> × </a><span> Une erreur est survenue et l'administrateur a été prévenu.</span></div></div>");
      }
    });
  }
}

function editPreseizure(id){
  $('#preseizuresModals #preseizureEdition').modal('show');

  $.ajax({
    url: '/account/documents/preseizure/'+id+'/edit',
    data: '',
    dataType: "html",
    type: "GET",
    beforeSend: function() {
      logBeforeAction("Traitement en cours");
    },
    success: function(data){
      logAfterAction();
      $('#preseizuresModals #preseizureEdition .modal-body').html(data);

      //add and initialize datepicker
      $('#preseizuresModals #preseizureEdition .modal-body .datepicker').find('input').after('<span class="add-on" style="width: 0px; height: 35px"></span>');
      $('#preseizuresModals #preseizureEdition .modal-body .datepicker').datepicker({ format: 'yyyy-mm-dd', language: 'fr', orientation: 'bottom auto' });
    },
    error: function(data){
      logAfterAction();
      $('#preseizuresModals #preseizureEdition .modal-body').html("<div class='row-fluid'><div class='span12 alert alert-error'><a class='close' data-dismiss='alert'> × </a><span> Une erreur est survenue et l'administrateur a été prévenu.</span></div></div>");
    }
  });
}

function editPreseizureAccount(id){
  $('#preseizuresModals #preseizureAccountEdition').modal('show');

  $.ajax({
    url: '/account/documents/preseizure/account/'+id+'/edit',
    data: '',
    dataType: "html",
    type: "GET",
    beforeSend: function() {
      logBeforeAction("Traitement en cours");
    },
    success: function(data){
      logAfterAction();
      $('#preseizuresModals #preseizureAccountEdition .modal-body').html(data)
    },
    error: function(data){
      logAfterAction();
      $('#preseizuresModals #preseizureAccountEdition .modal-body').html("<div class='row-fluid'><div class='span12 alert alert-error'><a class='close' data-dismiss='alert'> × </a><span> Une erreur est survenue et l'administrateur a été prévenu.</span></div></div>");
    }
  });
}

function editPreseizureEntry(id){
  $('#preseizuresModals #preseizureEntryEdition').modal('show');

  $.ajax({
    url: '/account/documents/preseizure/entry/'+id+'/edit',
    data: '',
    dataType: "html",
    type: "GET",
    beforeSend: function() {
      logBeforeAction("Traitement en cours");
    },
    success: function(data){
      logAfterAction();
      $('#preseizuresModals #preseizureEntryEdition .modal-body').html(data);
    },
    error: function(data){
      logAfterAction();
      $('#preseizuresModals #preseizureEntryEdition .modal-body').html("<div class='row-fluid'><div class='span12 alert alert-error'><a class='close' data-dismiss='alert'> × </a><span> Une erreur est survenue et l'administrateur a été prévenu.</span></div></div>");
    }
  });
}

function deliverPreseizures(link='all'){
  var id = 0;
  var ids = 0;

  if(link === 'all')
  {
    id = window.currentLink.parents("li").attr("id").split("_")[2];
    type = (window.currentLink.parents("li").hasClass('report'))? 'report' : 'pack';
    data = { type: type, id: id };
    $('#presPanel1 .header .actiongroup .do-deliverAllPreseizure').remove();
    $('#show_preseizures #lists_preseizures .preseizure a.tip_deliver').remove();
  }
  else if(link === 'selection')
  {
    ids  = window.preseizuresSelected;
    data = { ids: ids };
    ids.forEach(function(elem){
      $('#show_preseizures #lists_preseizures .preseizure#'+elem+' a.tip_deliver').remove();
    });
  }
  else
  {
    id = link.attr("data-id");
    data = { ids: id };
    link.remove();
  }

  $.ajax({
    url: '/account/documents/deliver_preseizures',
    data: data,
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
      $('.alerts').html("<div class='row-fluid'><div class='span12 alert alert-error'><a class='close' data-dismiss='alert'> × </a><span> Une erreur est survenue et l'administrateur a été prévenu.</span></div></div>");
    }
  });
}

function handlePreseizureSelection(id, type='toggle'){
  var found = window.preseizuresSelected.find(function(elem){ return elem == id });

  if( found && (type == 'unselect' || type == 'toggle') )
  {//already selected
    window.preseizuresSelected = window.preseizuresSelected.filter(function(elem){ return elem != id});
    $('#lists_preseizures .preseizure#'+id).removeClass('selected');

    $('#lists_preseizures .preseizure#'+id+' .actionbox a.tip_selection i').addClass('icon-ok');
    $('#lists_preseizures .preseizure#'+id+' .actionbox a.tip_selection i').removeClass('icon-ban-circle');
  }
  else if( !found && (type == 'select' || type == 'toggle') )
  {//not selected
    window.preseizuresSelected.push(id);
    $('#lists_preseizures .preseizure#'+id).addClass('selected');

    $('#lists_preseizures .preseizure#'+id+' .actionbox a.tip_selection i').addClass('icon-ban-circle');
    $('#lists_preseizures .preseizure#'+id+' .actionbox a.tip_selection i').removeClass('icon-ok');
  }

  if(window.preseizuresSelected.length > 0){
    $('#presPanel1 .header .actiongroup .do-deliverAllPreseizure').attr('style', 'border: 2px solid #B1D837; padding: 5px');
    $('#presPanel1 .header .actiongroup .do-exportSelectedPreseizures').attr('style', 'border: 2px solid #B1D837; padding: 5px 2px 5px 5px');
  }
  else{
    $('#presPanel1 .header .actiongroup .do-deliverAllPreseizure').attr('style', '');
    $('#presPanel1 .header .actiongroup .do-exportSelectedPreseizures').attr('style', '');
  }

  if(window.preseizuresSelected.length > 1)
    $('#presPanel1 .header .actiongroup .do-editSelectedPreseizures').removeClass('hide');
  else
    $('#presPanel1 .header .actiongroup .do-editSelectedPreseizures').addClass('hide');
}
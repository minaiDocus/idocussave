// fecth all preseizures of the pack
function getPreseizures(link, page=1, by_piece=null, then_pieces=false){
  if(page < 1 || window.preseizuresLoaderLocked)
    return false

  window.preseizuresLoaderLocked = true;

  var document_id = link.parents("li").attr("id").split("_")[2];
  var document_name = link.text();

  var filter = '&'+window.getParamsFromFilter();
  window.setParamsFilterText();

  var url = "/account/documents/"+document_id+"?source=report&fetch=preseizures&page="+page+filter;

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
        $('#presPanel1 #show_preseizures h4').text($('.preseizures .total_preseizures_count').text() + ' écriture(s) comptable(s)');

        window.preseizuresSelected = [];
        $('#presPanel1 .header .actiongroup .do-deliverAllPreseizure').attr('style', '');
        $('#presPanel1 .header .actiongroup .do-exportSelectedPreseizures').attr('style', '');

        var software_used = $('.software_used').text() || '';
        var need_delivery = $('.need_delivery').text() || 'no';

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
      
      initEventOnPreseizuresRefresh();
      window.initEventOnHoverOnInformation(); 
      initEventOnPiecesRefresh();
      initEventOnPreseizuresAccountRefresh();

      setTimeout(function(){
        window.preseizuresLoaderLocked = false;
      }, 1000);  
    },
    error: function(data){
      logAfterAction();
      $(".alerts").html("<div class='row-fluid'><div class='span12 alert alert-error'><a class='close' data-dismiss='alert'> × </a><span> Une erreur est survenue et l'administrateur a été prévenu.</span></div></div>");
      setTimeout(function(){
        window.preseizuresLoaderLocked = false;
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
    var elem = $(".preseizure#div_"+id);
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

        elem.html($(htmlDoc).find('#show_preseizures #lists_preseizures_content .preseizure#div_'+id).html());
        elem.removeClass("selected");

        initEventOnPreseizuresRefresh();
        initEventOnPreseizuresAccountRefresh();
        window.initEventOnHoverOnInformation();
        handlePreseizureSelection('', '');

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

function getPreseizureAccount(manual_id=[]){
  $('.content_details .list_preseizure_id').each(function(){
      var tab_id = $(this).val().replace(/[[\]]/g,"").replace(/\s/g,"").split(',');
      var li     = $(this).closest("li").attr("id");
      var verif_count_preseizure = [];
      if (manual_id.length != 0)
      {
        var verif_count_preseizure = tab_id;
        tab_id = manual_id;
      }

      $.each(tab_id, function( index, id ){        

        var elem = $(".preseizure_description #div_"+id);

        var exist = (elem.html() != '' && elem.html() != null && elem.html() != undefined) ? true : false;  

        var found = verif_count_preseizure.find(function(elem){ return elem == id});

        if((!exist && id !== undefined) || (manual_id.length != 0 && found !== undefined))
        {
          $.ajax({
            url: '/account/documents/preseizure_account/'+id,
            data: '',
            dataType: "html",
            type: "GET",
            success: function(data){
              logAfterAction();

              var html = elem.html(data);
              html.show();

              elem.removeClass("preseizure_selected active");
              if ($("#"+li+" .tab").length > 0)
                $("#span_"+id).removeClass("preseizure_selected");

              if (tab_id.length == 1 && manual_id.length == 0) {
                elem.css('margin-top','1%');
                $(".check_"+id).show();
              }
              else if (manual_id.length != 0) {
                if (verif_count_preseizure.length == 1)
                  $(".check_"+id).show();
              }

              if (!$('#span_'+id+".tab_preseizure_id").hasClass('tab_active') && $("#"+li+" .tab").length > 0)
                html.hide();

              handlePreseizureSelection(id, 'unselect');
              togglePreseizureAction();
              initEventOnPiecesRefresh();
              initEventOnPreseizuresAccountRefresh();
              initEventOnPreseizuresRefresh();
            },
            error: function(data){
              logAfterAction();
              elem.html('');
              $(".alerts").html("<div class='row-fluid'><div class='span12 alert alert-error'><a class='close' data-dismiss='alert'> × </a><span> Une erreur est survenue et l'administrateur a été prévenu.</span></div></div>");
            }
          });
        }
      });
    });  
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
      $('#preseizuresModals #preseizureAccountEdition').css({'width': '80%', 'left': '25%'});
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
      $('#show_preseizures #lists_preseizures .preseizure#div_'+elem+' a.tip_deliver').remove();
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

function handlePreseizureSelection(id_tmp, type='toggle'){
  var id = id_tmp.split('_')[1];
  var found = window.preseizuresSelected.find(function(elem){ return elem == id });

  if( found && (type == 'unselect' || type == 'toggle') )
  {//already selected
    window.preseizuresSelected = window.preseizuresSelected.filter(function(elem){ return elem != id});
    $('#lists_preseizures .preseizure#div_'+id).removeClass('selected');

    $('#lists_preseizures .preseizure#div_'+id+' .actionbox a.tip_selection i').addClass('icon-ok');
    $('#lists_preseizures .preseizure#div_'+id+' .actionbox a.tip_selection i').removeClass('icon-ban-circle');
  }
  else if( !found && (type == 'select' || type == 'toggle') )
  {//not selected
    window.preseizuresSelected.push(id);
    $('#lists_preseizures .preseizure#div_'+id).addClass('selected');

    $('#lists_preseizures .preseizure#div_'+id+' .actionbox a.tip_selection i').addClass('icon-ban-circle');
    $('#lists_preseizures .preseizure#div_'+id+' .actionbox a.tip_selection i').removeClass('icon-ok');
  }

  if(window.preseizuresSelected.length > 0){
    $('#presPanel1 .header .actiongroup .do-deliverAllPreseizure').attr('style', 'border: 2px solid #058acd; padding: 5px; border-radius: 3px');
    $('#presPanel1 .header .actiongroup .do-exportSelectedPreseizures').attr('style', 'border: 2px solid #058acd; padding: 5px 2px 5px 5px; border-radius: 3px');
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

function togglePreseizureAction(){  
  if ($(".preseizure_selected.active").length > 1){
    
    if ($(".tip_edit_multiple").html() == '')
    {
      $(".tip_edit_multiple").append('<i class="icon-edit"></i>');
    }
    $(".tip_edit_multiple").removeClass("hide");
    $(".tip_edit_multiple").css({'border' : '2px solid #058acd', 'padding' : '4px 4px 6px 4px', 'border-radius' : '3px'});
    $(".do-exportSelectedPreseizures").css({'border' : '2px solid #058acd', 'padding' : '4px 2px 6px 5px', 'border-radius' : '3px'});
    $(".do-deliverAllPreseizure").css({'border' : '2px solid #058acd', 'padding' : '4px 2px 6px 5px', 'border-radius' : '3px'});
  }
  else if ($(".preseizure_selected.active").length >= 1){      
    $(".tip_edit_multiple").addClass("hide");
    $(".tip_edit_multiple").html('').css({'border' : 'none', 'padding' : '0', 'border-radius' : '0'});
    $(".do-exportSelectedPreseizures").css({'border' : '2px solid #058acd', 'padding' : '4px 2px 6px 5px', 'border-radius' : '3px'});
    $(".do-deliverAllPreseizure").css({'border' : '2px solid #058acd', 'padding' : '4px 2px 6px 5px', 'border-radius' : '3px'});
  }
  else 
  { 
    $(".tip_edit_multiple").addClass("hide");   
    $(".tip_edit_multiple").html('').css({'border' : 'none', 'padding' : '0', 'border-radius' : '0'});
    $(".do-exportSelectedPreseizures").css({'border' : 'none', 'padding' : '0', 'border-radius' : '0'});
    $(".do-deliverAllPreseizure").css({'border' : 'none', 'padding' : '0', 'border-radius' : '0'});
  }
}

function updateAccountEntry(id_account,new_value,type,id,source)
{
  $.ajax({
    url: '/account/documents/preseizure/account/'+id+'/update',
    data: {id_account:id_account,new_value:new_value,type:type},
    dataType: "json",
    type: "POST",
    beforeSend: function() {
      logBeforeAction("Traitement en cours");
    },
    success: function(data){
      logAfterAction();
      initEventOnHoverOnInformation();
      if (window.currentView == 'pieces')
        getPreseizureAccount([id]);
      else
        refreshPreseizures([id]);
    },
    error: function(data){
      logAfterAction();
      $('.content_preseizure').prepend("<div class='row-fluid'><div class='span12 alert alert-error'><a class='close' data-dismiss='alert'> × </a><span> Une erreur est survenue et l'administrateur a été prévenu.</span></div></div>");
    }
  });
}

function updatePreseizureInformation(date="",deadline_date="",third_party="",id="")
{
  $.ajax({
    url: '/account/documents/preseizure/'+id+'/update',
    data: {date:date,deadline_date:deadline_date,third_party:third_party,partial_update:1},
    dataType: "json",
    type: "POST",
    beforeSend: function() {
      logBeforeAction("Traitement en cours");
    },
    success: function(data){
      logAfterAction();
      initEventOnHoverOnInformation();
      if (window.currentView == 'pieces')
        getPreseizureAccount([id]);
      else
        refreshPreseizures([id]);
    }
  });
}

function alertModificationPreseizureDelivered(id)
{  
  if ($("#alert_"+id).length == 0 && $("#delivered_"+id).val() == 1 && $(".is_collaborator").val() == 1)
  {
    $("#alert_irregular_debit_credit").modal("show");    
    $("#wrap").append('<input type="hidden" id="alert_'+id+'" value="1">');
  }  
}

function accountAutocompletion(input, params = {value: '', preseizure_id: 0, account_id: 0}){
  var html_autocomplete = input.parent().find('.suggestion_account_list');
  initEventOnPreseizuresRefresh();
  if(params.value.length > 0)
  {
    if (html_autocomplete.children().length == 0)
    {
      $.ajax({
        url: '/account/preseizure_accounts/accounts_list',
        data: params,
        type: "POST",
        success: function(data){
          html_autocomplete.show();
          html_autocomplete.html(data);
          html_autocomplete.find('ul').children().hide();
          var result_found = html_autocomplete.find('ul').children('[id*='+params.value+']');

          if(result_found.length > 0)
            result_found.show();
          else
            html_autocomplete.find('.no_result').show();
          initEventOnPreseizuresRefresh();
        }
      });
    }
    else
    {
      html_autocomplete.hide();
      html_autocomplete.find('ul').children().hide();
      var result_found = html_autocomplete.find('ul').children('[id*='+params.value+']');

      if(result_found.length > 0)
        result_found.show();
      else
        html_autocomplete.find('.no_result').show();
      html_autocomplete.show();
      initEventOnPreseizuresRefresh();
    }
  }
  else
  {
    html_autocomplete.addClass('hide');
  }
}
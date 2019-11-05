var initEventOnPreseizuresRefresh = function(){

  $("a.tip_selection").unbind('click');
  $("a.tip_selection").click(function(e){
    e.preventDefault();
    handlePreseizureSelection($(this).attr("data-id"));
  });

  $("a.do-selectAllPreseizures").unbind('click');
  $("a.do-selectAllPreseizures").click(function(e){
    e.preventDefault();
    $("#lists_preseizures .preseizure").each(function(){
      handlePreseizureSelection($(this).attr("id"), 'select');
    });
  });

  $("a.do-unselectAllPreseizures").unbind('click');
  $("a.do-unselectAllPreseizures").click(function(e){
    e.preventDefault();
    $("#lists_preseizures .preseizure").each(function(){
      handlePreseizureSelection($(this).attr("id"), 'unselect');
    });
  });

  $("a.tip_edit").unbind('click');
  $("a.tip_edit").click(function(e){
    e.preventDefault();    
    editPreseizure($(this).attr("data-id"));
  });

  $("a.tip_deliver").unbind('click');
  $("a.tip_deliver").click(function(e){
    e.preventDefault();
    var software_used = $('.software_used').text() || '';
    if(confirm("Vous êtes sur le point d'envoyer une écriture vers "+software_used+", Etes-vous sûr ?"))
      deliverPreseizures($(this));
  });

  $("a.do-deliverAllPreseizure").unbind('click');
  $("a.do-deliverAllPreseizure").click(function(e){
    e.preventDefault();

    var software_used = $('.software_used').text() || '';
    var confirm_text  = "Vous êtes sur le point d'envoyer toutes les écritures non livrées du lot vers "+software_used+", Etes-vous sûr ?";
    if(window.preseizuresSelected.length > 0)
      confirm_text = "Vous êtes sur le point d'envoyer "+window.preseizuresSelected.length+" écriture(s) non livrée(s) de la séléction vers "+software_used+", Etes-vous sûr ?";

    if(confirm(confirm_text))
    {
      if(window.preseizuresSelected.length > 0)
        deliverPreseizures('selection');
      else
        deliverPreseizures('all');
    }
  }); 

  $('.tab_preseizure_id').click(function(e){
    var document_li_id = $(this).parents("li").attr("id");
    $("#"+document_li_id+" .content_preseizure").hide();
    $("#"+document_li_id+" .tab").removeClass('tab_active');
    var tmp_id = $(this).attr('id');
    var id = tmp_id.split('_');
    $("#"+document_li_id+" #div_"+id[1]).show();
    $(this).addClass("tab_active");
  });
}

var initEventOnPreseizuresAccountRefresh = function(){
  $("a.tip_edit_entry_account").unbind('click');
  $("a.tip_edit_entry_account").click(function(e){
    e.preventDefault();
    editPreseizureAccount($(this).attr("data-id"))
  });
}

$('#preseizuresModals #exportSelectedPreseizures').on('show', function(){
  var id = 0;
  var ids = 0;
  var export_ids = 0;
  var export_type = '';
  var indication = 'toutes les écritures comptables du lot.';

  if(window.preseizuresSelected.length <= 0)
  {
    id = window.currentLink.parents("li").attr("id").split("_")[2];
    type = (window.currentLink.parents("li").hasClass('report'))? 'report' : 'pack';
    data = { type: type, id: id };
    export_type = type;
    export_ids = id;
  }
  else
  {
    indication = window.preseizuresSelected.length + ' écriture(s) comptable(s) du lot.';
    data = { ids: window.preseizuresSelected };
    export_type = 'preseizure';
    export_ids  = window.preseizuresSelected.join(',');
  }

  $('#exportSelectedPreseizures .preseizures_indication').html(indication);
  $('#exportSelectedPreseizures #validatePreseizuresExport').addClass('hide');
  $('#exportSelectedPreseizures #export_format').html('');

  $('#exportSelectedPreseizures #preseizuresExportForm #export_type').val(export_type);
  $('#exportSelectedPreseizures #preseizuresExportForm #export_ids').val(export_ids);

  $.ajax({
    url: '/account/documents/select_to_export',
    data: data,
    dataType: "json",
    type: "POST",
    beforeSend: function() {
      logBeforeAction("Traitement en cours");
    },
    success: function(data){
      logAfterAction();
      var options = '';

      if(data.options.length > 0)
      {
        data.options.forEach(function(elem){ options += '<option value="'+elem[1]+'">'+elem[0]+'</option>'; });
        $('#exportSelectedPreseizures #export_format').html(options);
        $('#exportSelectedPreseizures #export_format').change();
        $('#exportSelectedPreseizures #validatePreseizuresExport').removeClass('hide');
      }
      else
      {
        $('#exportSelectedPreseizures #export_format').html('<option value="">Aucun format d\'export disponible</option>');
      }
    },
    error: function(data){
      logAfterAction();
      $('#preseizuresModals #exportSelectedPreseizures .modal-body').prepend("<div class='row-fluid'><div class='span12 alert alert-error'><a class='close' data-dismiss='alert'> × </a><span> Une erreur est survenue et l'administrateur a été prévenu.</span></div></div>");
    }
  });
});

$('#preseizuresFilterForm #validatePreseizuresFilter').click(function(e){
  if(window.currentLink === null || window.currentLink === undefined)
    return false

  getPreseizures(window.currentLink, 1);
});

$('#preseizuresFilterForm #initPreseizuresFilter').click(function(e){
  if(window.currentLink === null || window.currentLink === undefined)
    return false

  getPreseizures(window.currentLink, 1, null, false);
});

$('#preseizuresModals #preseizureEdition #editPreseizureSubmit').click(function(e){
  e.preventDefault();

  var id = $('#preseizuresModals #preseizureEdition #pack_report_preseizure_id').val();
 
  $.ajax({
    url: '/account/documents/preseizure/'+id+'/update',
    data: $('#preseizuresModals #preseizureEdition form').serialize(),
    dataType: "json",
    type: "POST",
    beforeSend: function() {
      logBeforeAction("Traitement en cours");
    },
    success: function(data){
      logAfterAction();

      if (window.currentView == 'pieces')
        getPreseizureAccount([id]);
      else 
        refreshPreseizures([id]);

      if(data.error == '')
        $('#preseizuresModals #preseizureEdition').modal('hide');
      else
        $('#preseizuresModals #preseizureEdition .modal-body').prepend("<div class='row-fluid'><div class='span12 alert alert-error'><a class='close' data-dismiss='alert'> × </a><span>"+data.error+"</span></div></div>");
    },
    error: function(data){
      logAfterAction();
      $('#preseizuresModals #preseizureEdition .modal-body').prepend("<div class='row-fluid'><div class='span12 alert alert-error'><a class='close' data-dismiss='alert'> × </a><span> Une erreur est survenue et l'administrateur a été prévenu.</span></div></div>");
    }
  });
});

$('#preseizuresModals #preseizureAccountEdition #editPreseizureAccountSubmit').click(function(e){
  e.preventDefault();

  var id = $('#preseizuresModals #preseizureAccountEdition #preseizure_id').val();

  $.ajax({
    url: '/account/documents/preseizure/account/'+id+'/update',
    data: $('#preseizuresModals #preseizureAccountEdition form').serialize(),
    dataType: "json",
    type: "POST",
    beforeSend: function() {
      logBeforeAction("Traitement en cours");
    },
    success: function(data){
      logAfterAction();

      if (window.currentView == 'pieces')
        getPreseizureAccount([id]);
      else 
        refreshPreseizures([id]);

      if(data.error == ''){
        $('#preseizuresModals #preseizureAccountEdition').modal('hide');        
      }
      else{
        $('#preseizuresModals #preseizureAccountEdition .modal-body').prepend("<div class='row-fluid'><div class='span12 alert alert-error'><a class='close' data-dismiss='alert'> × </a><span>"+data.error+"</span></div></div>");
      }
    },
    error: function(data){
      logAfterAction();
      $('#preseizuresModals #preseizureAccountEdition .modal-body').prepend("<div class='row-fluid'><div class='span12 alert alert-error'><a class='close' data-dismiss='alert'> × </a><span> Une erreur est survenue et l'administrateur a été prévenu.</span></div></div>");
    }
  });
});

$('#preseizuresModals #preseizureEntryEdition #editPreseizureEntrySubmit').click(function(e){
  e.preventDefault();

  var id = $('#preseizuresModals #preseizureEntryEdition #pack_report_preseizure_entry_id').val()
  $.ajax({
    url: '/account/documents/preseizure/entry/'+id+'/update',
    data: $('#preseizuresModals #preseizureEntryEdition form').serialize(),
    dataType: "json",
    type: "POST",
    beforeSend: function() {
      logBeforeAction("Traitement en cours");
    },
    success: function(data){
      logAfterAction();
      if(data.error == ''){
        $('#preseizuresModals #preseizureEntryEdition').modal('hide');
      }
      else{
        $('#preseizuresModals #preseizureEntryEdition .modal-body').prepend("<div class='row-fluid'><div class='span12 alert alert-error'><a class='close' data-dismiss='alert'> × </a><span>"+data.error+"</span></div></div>");
      }
    },
    error: function(data){
      logAfterAction();
      $('#preseizuresModals #preseizureEntryEdition .modal-body').prepend("<div class='row-fluid'><div class='span12 alert alert-error'><a class='close' data-dismiss='alert'> × </a><span> Une erreur est survenue et l'administrateur a été prévenu.</span></div></div>");
    }
  });
});

$("#preseizuresModals #editSelectedPreseizures #validatePreseizuresEdition").click(function(e){
  e.preventDefault();  
  $.ajax({
    url: '/account/documents/update_multiple_preseizures',
    data: { ids: window.preseizuresSelected, preseizures_attributes: $('#preseizuresModals #editSelectedPreseizures #preseizuresEditionForm').serializeObject() },
    dataType: "json",
    type: "POST",
    beforeSend: function() {
      logBeforeAction("Traitement en cours");
    },
    success: function(data){
      logAfterAction();
      if(data.error == '')
      {
        $('#preseizuresModals #editSelectedPreseizures').modal('hide');

        if (window.currentView == 'pieces')
          getPreseizureAccount(window.preseizuresSelected);
        else 
          refreshPreseizures(window.preseizuresSelected);
      }
      else
      {
        $('#preseizuresModals #editSelectedPreseizures .modal-body').prepend("<div class='row-fluid'><div class='span12 alert alert-error'><a class='close' data-dismiss='alert'> × </a><span>"+data.error+"</span></div></div>");
      }
    },
    error: function(data){
      logAfterAction();
      $('#preseizuresModals #editSelectedPreseizures .modal-body').prepend("<div class='row-fluid'><div class='span12 alert alert-error'><a class='close' data-dismiss='alert'> × </a><span> Une erreur est survenue et l'administrateur a été prévenu.</span></div></div>");
    }
  });
});

$("#preseizuresModals #exportSelectedPreseizures #export_format").on('change', function(e){
  var export_type     = $('#exportSelectedPreseizures #preseizuresExportForm #export_type').val();
  var export_ids      = $('#exportSelectedPreseizures #preseizuresExportForm #export_ids').val();
  var export_format   = $(this).val();

  var params64      = btoa(export_type+'&'+export_ids+'&'+export_format); //Encoding to base64
  var generetedLink = $('#exportSelectedPreseizures #validatePreseizuresExport').attr('data-base-link') + '/' + params64;
  $('#exportSelectedPreseizures #validatePreseizuresExport').attr('href', generetedLink);
});
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

  $("a.tip_details").unbind('click');
  $("a.tip_details").click(function(e){
    e.preventDefault();
    getPreseizureAccount($(this).attr("data-id"));
  });

  $("a.tip_edit").unbind('click');
  $("a.tip_edit").click(function(e){
    e.preventDefault();
    editPreseizure($(this).attr("data-id"));
  });

  $("a.tip_deliver").unbind('click');
  $("a.tip_deliver").click(function(e){
    e.preventDefault();

    var software_used = $('#show_preseizures .software_used').text() || '';
    if(confirm("Vous êtes sur le point d'envoyer une écriture vers "+software_used+", Etes-vous sûr ?"))
      deliverPreseizures($(this));
  });

  $("a.do-deliverAllPreseizure").unbind('click');
  $("a.do-deliverAllPreseizure").click(function(e){
    e.preventDefault();

    var software_used = $('#show_preseizures .software_used').text() || '';
    var confirm_text  = "Vous êtes sur le point d'envoyer toutes les écritures non livrées du lot vers "+software_used+", Etes-vous sûr ?";
    if(window.preseizuresSelected.length > 0)
      confirm_text = "Vous êtes sur le point d'envoyer toutes les écritures non livrées de la séléction vers "+software_used+", Etes-vous sûr ?";

    if(confirm(confirm_text))
    {
      if(window.preseizuresSelected.length > 0)
        deliverPreseizures('selection');
      else
        deliverPreseizures('all');
    }
  });

  $('.do-goToPiece').unbind('click');
  $('.do-goToPiece').click(function(e){
    e.preventDefault();
    var piece_id = $(this).attr('data-id');
    window.currentView = 'pieces';
    showPieces(window.currentLink, 1, piece_id);
  });

  $('a#do-showAllPreseizures').unbind('click');
  $('a#do-showAllPreseizures').click(function(e){
    e.preventDefault();
    getPreseizures(window.currentLink, 1);
  });
}

var initEventOnPreseizuresAccountRefresh = function(){
  $("a.tip_edit_account").unbind('click');
  $("a.tip_edit_account").click(function(e){
    e.preventDefault();
    editPreseizureAccount($(this).attr("data-id"))
  });

  $("a.tip_edit_entry").unbind('click');
  $("a.tip_edit_entry").click(function(e){
    e.preventDefault();
    editPreseizureEntry($(this).attr("data-id"))
  });
}

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

  var id = $('#preseizuresModals #preseizureAccountEdition #pack_report_preseizure_account_id').val();
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
      if(data.error == ''){
        $('#preseizuresModals #preseizureAccountEdition').modal('hide');
        getPreseizureAccount($('#preseizuresModals #preseizureAccountEdition #preseizure_id').val(), true);
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
        getPreseizureAccount($('#preseizuresModals #preseizureEntryEdition #preseizure_id').val(), true);
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
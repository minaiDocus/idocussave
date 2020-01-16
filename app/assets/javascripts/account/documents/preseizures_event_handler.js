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

    var filter_visibility = $('.filter_indication').is(':visible') || false;

    if(confirm(confirm_text))
    {
      if(window.preseizuresSelected.length > 0)
        deliverPreseizures('selection');
      else if (filter_visibility == true)
        deliverPreseizures('filter');
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

  $("div.entries table td.account .content_account").unbind('click');
  $('div.entries table td.account .content_account').on("click",function(e){
    e.stopPropagation();
    var id = $(this).closest(".content_preseizure").attr('id').split('_')[1];
    var account_id = $(this).closest("tr").find('.account_id_hidden').val();
    alertModificationPreseizureDelivered(id);
    var edit_content     = $(this).parent().find('.edit_account');    
    var content_account  = $(this);
    var input            = edit_content.children();
    if (input.length > 0)
    {
      window.input_can_focusout = true;
      edit_content.show();
      content_account.hide();
      input.unbind('focusout');
      input.select();
      input.blur().focus().focusout(function(){
        if(window.input_can_focusout){
          var new_value = $(this).val();
          if (new_value == $(this).attr('placeholder') || new_value == "")
          {
            edit_content.hide();
            content_account.show();
            if (new_value == "")
            {
              $(this).val($(this).attr('placeholder'));
            }
          }
          else
          {
            updateAccountEntry(account_id,new_value,"account",id);
          }
        }

      }).on('keypress',function(e) {          
            if(e.which == 13) {               
              var new_value = $(this).val();
              if (new_value == $(this).attr('placeholder') || new_value == "")
              {
                edit_content.hide();
                content_account.show();
                if (new_value == "")
                {
                  $(this).val($(this).attr('placeholder'));
                }
              }
              else
              {               
                updateAccountEntry(account_id,new_value,"account",id);
              }          
          };
        }).on('keyup', function(e){
          var value  = $(this).val()
          var params = { preseizure_id: id, account_id: account_id, value: value }
          accountAutocompletion($(this), params)
        });
    }
  });

  $("div.entries table td.entry .content_amount").unbind('click');
  $('div.entries table td.entry .content_amount').click(function(e){
    e.stopPropagation();
    var id = $(this).closest(".content_preseizure").attr('id').split('_')[1];
    alertModificationPreseizureDelivered(id);
    var edit_content    = $(this).parent().find('.edit_amount');
    var content_amount  = $(this);
    var input           = edit_content.find('input').first();
    if (input.length > 0)
    {
      edit_content.show();
      content_amount.hide();
      input.unbind('focusout');
      input.select();
      input.blur().focus().focusout(function(){
        var new_value   = $(this).val();
        if (new_value == $(this).attr('placeholder') || new_value == "")
        {
          edit_content.hide();
          content_amount.show();
          if (new_value == "")
          {
            $(this).val($(this).attr('placeholder'));
          }
        }
        else
        {
          var account_id = $(this).closest("tr").find('.entry_id_hidden').val();          
          updateAccountEntry(account_id,new_value,"entry",id);
        }
      }).on('keypress',function(e) {
            if(e.which == 13) {               
              var new_value   = $(this).val();
              if (new_value == $(this).attr('placeholder') || new_value == "")
              {
                edit_content.hide();
                content_amount.show();
                if (new_value == "")
                {
                  $(this).val($(this).attr('placeholder'));
                }
              }
              else
              {
                var account_id = $(this).closest("tr").find('.entry_id_hidden').val();
                var id = $(this).closest(".content_preseizure").attr('id').split('_')[1];
                updateAccountEntry(account_id,new_value,"entry",id);
              }        
          };
        });
    }
  });

  $('div.entries table td.entry').mouseover(function(){
    if ($('.is_collaborator').val() == '1')
    {
      $(this).find('.content_amount span').show();
    }
  }).mouseout(function(){
    $(this).find('.content_amount span').hide();
  });

  $('.debit_or_credit').unbind('click');
  $('.debit_or_credit').click(function(e){
    e.stopPropagation();
    var id = $(this).closest(".content_preseizure").attr('id').split('_')[1];
    alertModificationPreseizureDelivered(id);
    var entry_type = $(this).closest('td').find('.entry_type').val();
    var account_id = $(this).closest("tr").find('.entry_id_hidden').val();    
    if (entry_type == 1)
    {
      updateAccountEntry(account_id,2,"credit_to_debit",id);
    }
    else
    {
      updateAccountEntry(account_id,1,"credit_to_debit",id);
    }
  });

  $("table.information tbody tr td.third_party .content_third_party").unbind('click');
  $("table.information tbody tr td.third_party .content_third_party").click(function(e){
    e.stopPropagation();
    var edit_third_party = $(this).parent().find('.edit_content_third_party');
    var content_account  = $(this);
    var input            = edit_third_party.children();
    if (input.length > 0)
    {
      edit_third_party.show();
      content_account.hide();
      input.unbind('focusout');
      input.select();
      input.blur().focus().focusout(function(){
        var new_third_party = $(this).val();
        if (new_third_party == $(this).attr('placeholder') || new_third_party == "")
        {
          edit_third_party.hide();
          content_account.show();
          if (new_third_party == "")
          {
            $(this).val($(this).attr('placeholder'));
          }
        }
        else
        {
          edit_third_party.find('input').prop("placeholder",new_third_party);
          var id = $(this).closest(".content_preseizure").attr('id').split('_')[1];
          updatePreseizureInformation("","",new_third_party,id);
        }
      }).on('keypress',function(e) {
            if(e.which == 13) {               
              var new_third_party = $(this).val();
              if (new_third_party == $(this).attr('placeholder') || new_third_party == "" )
              {
                edit_third_party.hide();
                content_account.show();
                if (new_third_party == "")
                {
                  $(this).val($(this).attr('placeholder'));
                }
              }
              else
              {
                edit_third_party.find('input').prop("placeholder",new_third_party);
                var id = $(this).closest(".content_preseizure").attr('id').split('_')[1];
                updatePreseizureInformation("","",new_third_party,id);
              }        
          };
        });
    }
  });

  $("table.information tbody tr td.date").unbind('click');
  $("table.information tbody tr td.date").click(function(e){
    e.stopPropagation();
    var td = $(this);
    var id_name          = $(this).attr('id');
    var edit_third_party = $(this).find('.edit_content_'+id_name);
    var content_account  = $(this).find('.content_'+id_name);
    var input            = edit_third_party.children();

    if (input.length > 0)
    {
      $('.editable_date').hide()
      $('.label_date').show()

      var new_value      = "";

      edit_third_party.show();
      content_account.hide();
      input.unbind('focusout');
      
      input.off("changeDate");
      var id = input.closest(".content_preseizure").attr('id').split('_')[1];           
      input.datepicker({ format: 'yyyy-mm-dd', language: 'fr', orientation : 'bottom auto'}).on('changeDate', function(e){
        e.stopPropagation();        
        new_value = $(this).val();
        if (new_value != "")
        {
          edit_third_party.find('input').prop("placeholder",new_value);
          content_account.text(new_value);
          edit_third_party.hide();
          content_account.show();
          $('.datepicker').hide();          
          if (id_name == "date")
          {
            updatePreseizureInformation(new_value,"","",id);
          }
          else
          {
            updatePreseizureInformation("",new_value,"",id);
          }
        }
      }).blur().focus().focusout(function(e){
        var visible = $('div.datepicker.datepicker-dropdown').is(':visible')

        if(!visible){
          edit_third_party.hide();
          content_account.show();
        }
      });  
    }
  });

  $(".suggestion_account_list ul li").unbind('click').unbind('mouseout').unbind('mouseover');
  $(".suggestion_account_list ul li").on('click',function(e){
    e.preventDefault();
    $(this).closest(".edit_account").find('input').val($(this).attr('id')).blur().focus();
    $(this).closest(".suggestion_account_list").hide();
    return false;
  }).on('mouseover', function(e){
    window.input_can_focusout = false
  }).on('mouseout', function(e){
    window.input_can_focusout = true
  });
}

var initEventOnPreseizuresAccountRefresh = function(){
  $("a.tip_edit_entry_account").unbind('click');
  $("a.tip_edit_entry_account").click(function(e){
    e.preventDefault();
    editPreseizureAccount($(this).attr("data-id"))
  });
}

$('#preseizuresModals #exportSelectedPreseizures').on('show.bs.modal', function(){
  var id  = 0;
  var ids = 0;
  var idt = [];
  var export_ids = 0;
  var export_type = '';
  var indication = 'toutes les écritures comptables du lot.';
  var filter_visibility = $('.filter_indication').is(':visible') || false;

  if(window.preseizuresSelected.length > 0)
  {
    indication = window.preseizuresSelected.length + ' écriture(s) comptable(s) du lot.';
    data = { ids: window.preseizuresSelected };
    export_type = 'preseizure';
    export_ids  = window.preseizuresSelected.join(',');
  }
  else if (filter_visibility == true)
  {
    type = (window.currentLink.parents("li").hasClass('report'))? 'report' : 'pack';

    if (type == 'report')
    {
      $(".preseizure.content_preseizure").each(function(e){
        idt.push($(this).attr('id').split("_")[1]);
      });
    }
    else
    {
      $(".check_modif_preseizure input").each(function(e){
        idt.push($(this).attr('id').split("_")[1]);
      });
    }

    ids  = idt.join(',');
    data = { ids: ids };
    export_type = 'preseizure';
    export_ids  = ids;
    indication  = 'les écriture(s) comptable(s) filtrée(s) du lot.'
  }
  else
  {
    id = window.currentLink.parents("li").attr("id").split("_")[2];
    type = (window.currentLink.parents("li").hasClass('report'))? 'report' : 'pack';
    data = { type: type, id: id };
    export_type = type;
    export_ids = id;
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
      $('#preseizuresModals #exportSelectedPreseizures .modal-body').prepend("<div class='row-fluid'><div class='span12 alert alert-danger'><a class='close' data-dismiss='alert'> × </a><span> Une erreur est survenue et l'administrateur a été prévenu.</span></div></div>");
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
        $('#preseizuresModals #preseizureEdition .modal-body').prepend("<div class='row-fluid'><div class='span12 alert alert-danger'><a class='close' data-dismiss='alert'> × </a><span>"+data.error+"</span></div></div>");
    },
    error: function(data){
      logAfterAction();
      $('#preseizuresModals #preseizureEdition .modal-body').prepend("<div class='row-fluid'><div class='span12 alert alert-danger'><a class='close' data-dismiss='alert'> × </a><span> Une erreur est survenue et l'administrateur a été prévenu.</span></div></div>");
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
        $('#preseizuresModals #preseizureAccountEdition .modal-body').prepend("<div class='row-fluid'><div class='span12 alert alert-danger'><a class='close' data-dismiss='alert'> × </a><span>"+data.error+"</span></div></div>");
      }
    },
    error: function(data){
      logAfterAction();
      $('#preseizuresModals #preseizureAccountEdition .modal-body').prepend("<div class='row-fluid'><div class='span12 alert alert-danger'><a class='close' data-dismiss='alert'> × </a><span> Une erreur est survenue et l'administrateur a été prévenu.</span></div></div>");
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
        $('#preseizuresModals #preseizureEntryEdition .modal-body').prepend("<div class='row-fluid'><div class='span12 alert alert-danger'><a class='close' data-dismiss='alert'> × </a><span>"+data.error+"</span></div></div>");
      }
    },
    error: function(data){
      logAfterAction();
      $('#preseizuresModals #preseizureEntryEdition .modal-body').prepend("<div class='row-fluid'><div class='span12 alert alert-danger'><a class='close' data-dismiss='alert'> × </a><span> Une erreur est survenue et l'administrateur a été prévenu.</span></div></div>");
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

      refreshPreseizures(window.preseizuresSelected);

      if(data.error == '')
      {
        $('#preseizuresModals #editSelectedPreseizures').modal('hide');

        if (window.currentView == 'pieces')
          getPreseizureAccount(window.preseizuresSelected);
        else 
          refreshPreseizures(window.preseizuresSelected);
        window.preseizuresSelected = []
        $('input[type="checkbox"]').prop("checked",false);
      }
      else
      {
        $('#preseizuresModals #editSelectedPreseizures .modal-body').prepend("<div class='row-fluid'><div class='span12 alert alert-danger'><a class='close' data-dismiss='alert'> × </a><span>"+data.error+"</span></div></div>");
      }
    },
    error: function(data){
      logAfterAction();
      $('#preseizuresModals #editSelectedPreseizures .modal-body').prepend("<div class='row-fluid'><div class='span12 alert alert-danger'><a class='close' data-dismiss='alert'> × </a><span> Une erreur est survenue et l'administrateur a été prévenu.</span></div></div>");
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
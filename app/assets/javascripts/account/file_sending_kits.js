
function appliedManualPaperSetOrder(){

  $('#loadingPage').addClass('hide');

  var elements = $('tbody#fsk_paper_set_orders tr')
  if (elements.length > 0) {
    var total_price = 0
    elements.each(function(index, element){
      var period = 1;
      var price = 0
      var period_duration = parseInt($(element).find('#fsk_order_period_duration').val());
      var ms_day = 1000*60*60*24*28;
      var start_date = new Date($(element).find('#fsk_orders_paper_set_start_date').val());
      var end_date   = new Date($(element).find('#fsk_orders_paper_set_end_date').val());

      if(start_date <= end_date){
        var count = Math.floor(Math.abs(end_date - start_date) / ms_day) + period_duration;
        period = (count / period_duration) - 1;

        var manual_paper_set_order  = $(element).find('#fsk_manual_paper_set_order');
        if(manual_paper_set_order.length > 0 && manual_paper_set_order.val() == 'true'){
          paper_set_folder_count = parseInt($(element).find("#fsk_order_paper_set_folder_count").val());
          price = paper_set_folder_count * (period + 1);
        }

        // $(element).find('#fsk_order_paper_set_price').html(price + ",00€")
        $(element).find('#fsk_order_paper_set_price').html("0,00€");
        $(element).find('span.error_info').html('');
      }
      else
      {
        price = 0;
        $(element).find('span.error_info').html('<span class="alert alert-danger">Interval de date invalide</span>');
      }

      if ($(element).find('input.fsk_user_checked').is(':checked')){
        total_price += price
      }
    });

    // $('.fsk_total_price').html(total_price + ",00€ HT")
    $('.fsk_total_price').html("0,00€ HT")
  }

  if ($('form.fsk_paper_set_orders').length > 0){
    $("#fsk_all_users_checked").click(function(){
      $('input:checkbox.fsk_user_checked').not(this).prop('checked', this.checked);
      checkGenerationButton();
    });
  }

  checkGenerationButton();
}


function checkGenerationButton(){
  $('#generate-manual-paper-set-order').prop('disabled', 'disabled');
  $('input:checkbox.fsk_user_checked').each(function(e){
    if( $(this).is(':checked') ){
      $('#generate-manual-paper-set-order').removeAttr('disabled', 'disabled');
    }
  });
}

function generateManualPaperSetOrder(){
  $("#generate-manual-paper-set-order").click(function(e) {
    e.preventDefault();
    var form = $('form.fsk_paper_set_orders');
    var organizationId = $('#fsk_manual_paper_set_order').data('id');
    $('body').append('<div class="manual-paper-set-loading-content" style="position: absolute;z-index: 1000;width: 100%;height: 100%;top: 0;left: 0;"></div>');
    $.ajax({
      url: "/account/organizations/" + organizationId + "/file_sending_kit/generate",
      data: form.serialize(),
      dataType: "json",
      type: "POST",
      beforeSend: function() {
        $('#download-manual-paper-set-order .download-manual-paper-set-order-folder-pdf').hide();
        $('#download-manual-paper-set-order .pending-generation').remove();
        $('#download-manual-paper-set-order .error-generation').remove();
        $('#download-manual-paper-set-order .success-generation').remove();
        $('#download-manual-paper-set-order').append('<span class="alert alert-info show-notify-content blink pending-generation">Génération de fichier de commande en cours ... veuillez patienter svp<span/>');
        $(".canceling-manual-order").attr("disabled","disabled");
        $("#generate-manual-paper-set-order").attr("disabled","disabled");
        $('#loadingPage').removeClass('hide')
      },
      success: function(data){
        $(".manual-paper-set-loading-content").remove();
        $('#loadingPage').addClass('hide');
        $('#download-manual-paper-set-order .show-notify-content').hide('fade', 100);
        $('#download-manual-paper-set-order .generated-success').append('<span class="alert alert-success show-content success-generation">Votre fichier de commande a bien été généré =><span/>')
        $('#download-manual-paper-set-order .download-manual-paper-set-order-folder-pdf').show();
        $("#generate-manual-paper-set-order").removeAttr("disabled");
        $(".canceling-manual-order").removeAttr("disabled");

        // setTimeout(function(){ $('#download-manual-paper-set-order a.download-manual-paper-set-order-folder-pdf').trigger('click') }, 1000);
      },
      error: function(data){
        console.error(data);
        var message = 'Une erreur a été rencontré lors de la régénération de votre commande ... veuillez réessayer svp'
        if(data.status == '603')
          message = data.responseText
        $(".manual-paper-set-loading-content").remove();
        $('#loadingPage').addClass('hide');
        $('#download-manual-paper-set-order .pending-generation').remove();
        $('#download-manual-paper-set-order .success-generation').remove();
        $('#download-manual-paper-set-order').append('<span class="alert alert-danger show-notify-content error-generation">' + message + '<span/>');
        $("#generate-manual-paper-set-order").attr("disabled","disabled");
        $("#generate-manual-paper-set-order").removeAttr("disabled");
        $(".canceling-manual-order").removeAttr("disabled");
      }
    });
  });
}


jQuery(function () {
  $('select').on('change', function() {
    appliedManualPaperSetOrder();
  });

  $('input.fsk_user_checked').on('click', function() {
    appliedManualPaperSetOrder();
  })

  // $('#download-manual-paper-set-order a.download-manual-paper-set-order-folder-pdf').on('click',  function(e) {
  //   // e.preventDefault();
  //   // var url    = $("#download-manual-paper-set-order a.download-manual-paper-set-order-folder-pdf").attr('href');
  //   // var target = $("#download-manual-paper-set-order a.download-manual-paper-set-order-folder-pdf").attr('target');
  //   // window.open(url, target);
  //   // window.location.href = url;
  //   location.reload();
  // })

  appliedManualPaperSetOrder();

  generateManualPaperSetOrder();
});
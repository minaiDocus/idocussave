function load_resources(resources) {
  for(i=0;i<10;i++){
    (function(counter) {
      var resource = resources[counter];
      $.ajax({
        url: '/admin/' + resource,
        dataType: 'html',
        type: 'GET',
        success: function (data) {
          $('#' + resource).html(data);
          $('a[href="#' + resource + '"] > .badge').text($('#' + resource + ' table').data('total'));
        }
      });
    })(i);
  }
}

$(document).ready(function() {
  var resources = [
    'ocr_needed_temp_packs',
    'bundle_needed_temp_packs',
    'processing_temp_packs',
    'currently_being_delivered_packs',
    'failed_packs_delivery',
    'blocked_pre_assignments',
    'awaiting_pre_assignments',
    'reports_delivery',
    'failed_reports_delivery',
    'awaiting_supplier_recognition'
  ];

  load_resources(resources);

  var interval_id = setInterval(function(){ load_resources(resources); }, 30000);
});

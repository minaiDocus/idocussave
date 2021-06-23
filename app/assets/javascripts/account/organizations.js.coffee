formValid = (e) ->
  datas = $('#slimpay_checkout_form').serialize();
  datas = datas.split('&');
  errors = [];

  datas.forEach((d) ->
    param = d.split('=');
    if param[0] == 'first_name' && !param[1]
      errors.push('Prénom est vide');
    if param[0] == 'last_name' && !param[1]
      errors.push('Nom est vide');
    if param[0] == 'email' && !param[1]
      errors.push('Email est vide');
    if param[0] == 'address' && !param[1]
      errors.push('Adresse est vide');
    if param[0] == 'city' && !param[1]
      errors.push('Ville est vide');
    if param[0] == 'postal_code' && !param[1]
      errors.push('Code postal est vide');
    if param[0] == 'country' && !param[1]
      errors.push('Pays est vide');
  )

  if errors.length > 0
    setAlert('<ul>'+errors.map((e)->'<li>'+e+'</li>').join('')+'</ul>', 'alert-danger');
    return false
  else
    return true

resetForm = ()->
  $('#slimpay_checkout_form #alert').addClass('hide');
  $('#slimpay_checkout_form #alert').html('');

  $('#slimpay_checkout #step2_section').html('');

  $('#slimpay_checkout #step1_buttons').removeClass('hide');
  $('#slimpay_checkout #step1_section').removeClass('hide');
  $('#slimpay_checkout #step2_section').addClass('hide');

  $('#slimpay_checkout #step_loader').addClass('hide');

  $('#slimpay_checkout_form input, #slimpay_checkout_form select').each((e)->
    $(this).removeAttr('disabled');
  );

setAlert = (message, type)->
  $('#slimpay_checkout_form #alert').removeClass('hide');
  $('#slimpay_checkout_form #alert').html('<div class="span12 alert '+type+'">'+message+'</div>');
  window.location.href = '#slimpay_checkout_form';

toggle_loading = ()->
  loader = $('#slimpay_checkout #step_loader')

  if loader.hasClass('hide')
    $('#slimpay_checkout #step1_buttons').addClass('hide');
    $('#slimpay_checkout #step_loader').removeClass('hide');
  else
    $('#slimpay_checkout #step1_buttons').removeClass('hide');
    $('#slimpay_checkout #step_loader').addClass('hide');

jQuery ->
  $('#slimpay_checkout #submitSlimpay').on('click', (e)->
    e.preventDefault();

    id = $('#slimpay_checkout_form #organization_id').val();
    url = "/account/organizations/"+id+"/prepare_payment";

    if formValid()
      $.ajax({
        url: url,
        data: $('#slimpay_checkout_form').serialize(),
        dataType: "json",
        type: "POST",
        beforeSend: ()->
          toggle_loading();
        success: (data)->
          toggle_loading();

          if(data.success)
            $('#slimpay_checkout #step1_section').addClass('hide');
            $('#slimpay_checkout #step2_section').removeClass('hide');
            $('#slimpay_checkout #step1_buttons').addClass('hide');

            if(data.frame_64)
              frame = atob(data.frame_64);
              $('#slimpay_checkout #step2_section').html('<div id="checkout_frame_loader" class="feedback active"><span style="margin-left: 40px">Chargement en cours ...</span></div>');
              $('#slimpay_checkout #step2_section').append(frame);
              setTimeout(()->
                $('#slimpay_checkout #step2_section #checkout_frame_loader').remove();
              , 4000)
            else if(data.redirect_uri)
              window.location.href = data.redirect_uri;
            else
              setAlert('Aucune redirection définie', 'alert-danger');
          else
            console.error(data.message);
            setAlert(data.message, 'alert-danger');

        error: (data)->
          toggle_loading();

          console.error(data);
          setAlert('Internal serveur error', 'alert-danger');
      });
  )

  $('#slimpay_checkout').on('hidden.bs.modal', (e)->
    id = $('#slimpay_checkout_form #organization_id').val();
    url = "/account/organizations/"+id+"/confirm_payment";

    $.ajax({
        url: url,
        dataType: "json",
        type: "POST",
        beforeSend: ()->
          $('#payments #payment_configuration_checker').removeClass('hide');
        success: (data)->
          $('#payments #payment_configuration_checker').addClass('hide');

          if data.success
            if data.debit_mandate['transactionStatus'] == 'success'
              $('#payments td#debit_state').html('<span class="badge badge-success fs-origin">OK</span>');
            else if data.debit_mandate['transactionStatus'] == 'started'
              $('#payments td#debit_state').html('<span class="badge badge-warning fs-origin">En attente utilisateur ...</span>');
            else
              $('#payments td#debit_state').html('<span class="badge badge-secondary fs-origin">Non configuré</span>');
              resetForm();

            $('#payments td#debit_bic').html(data.debit_mandate.bic);
            $('#payments td#debit_name').html(data.debit_mandate.title + ' ' + data.debit_mandate.firstName + ' ' + data.debit_mandate.lastName);
            $('#payments td#debit_email').html(data.debit_mandate.email);
        error: ()->
          $('#payments #payment_configuration_checker').addClass('hide');
          $('#payments td#debit_state').html("<span class='badge badge-danger fs-origin'>Une erreur inattendue s'est produite, Veuillez réessayer ultérieurement.</span>");
      });
  )

  $('.file_sending_kit_path').on 'click', (e) ->
      location.reload();
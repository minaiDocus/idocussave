cleanAnalytics = () ->
  window.analytics = null

  $('.analytic_box').addClass('hide')

  $('.analytic_select').html('')
  $('.analytic_select').val('').change()
  $('.analytic_ventilation').val(0).change()

getAnalyticsResume = () ->
  html =  '  <div class="analytic_resume">
              <div class="analytic_title">Analyse en cours :</div>
          '
  axis_option_name = ''

  for i in [1..3] by 1
    axis_value = $("#{window.analytic_target_form} .analytic_#{i}_name").val()
    if axis_value != '' && axis_value != undefined && axis_value != null
      axis_option_name = $("#analytic_fields #h_analytic_#{i}_name option[value='#{axis_value}']").text()
      html += "<div class='analytic_groups clearfix'>
                <div class='analytic_axis_name'>#{axis_option_name}</div>"

      for j in [1..3] by 1
        ventilation_value = $("#{window.analytic_target_form} .analytic_#{i}#{j}_ventilation").val()
        section_names = []
        for t in [1..3] by 1
          sect_value = $("#{window.analytic_target_form} .analytic_#{i}#{j}_axis#{t}").val()
          if sect_value != undefined && sect_value != '' && sect_value != null
            section_names.push( $("#analytic_fields #h_analytic_#{i}#{j}_axis#{t} option[value='#{sect_value}']").text() )
        if section_names.length > 0
          html += " <div class='analytic_section_group clearfix'>
                      <div class='analytic_section_name float-left'>- #{section_names.join(", ")}&nbsp;:&nbsp;</div>
                      <div class='analytic_section_ventilation float-left'>#{ventilation_value}%</div>
                    </div>
                  "
      html += '</div>'

  if axis_option_name == ''
    html = ''
  else
    html += '</div>'

  html

setDefaultAnalytics = (defaults) ->
  window.defaults = defaults
  if defaults != undefined && defaults != null && defaults != ''
    $('.with_default_analysis').show()

    for i in [1..3] by 1
      a_name        = defaults["a#{i}_name"]
      a_references  = defaults["a#{i}_references"]
      if a_name != undefined && a_name != null && a_name != ''
        $("#h_analytic_#{i}_name").val(a_name).change()

      if a_references != undefined && a_references != null && a_references != ''
        j = 0
        for ref in a_references
          j += 1
          $("#h_analytic_#{i}#{j}_ventilation").val(ref['ventilation'] || 0).change()

          for t in [1..3] by 1
            a_axis = ref["axis#{t}"]
            if a_axis != undefined && a_axis != null && a_axis != ''
              $("#h_analytic_#{i}#{j}_axis#{t}").val(a_axis).change()
              $("#section_group_#{i}#{j}").removeClass('hide')

    $('.default_values').remove()

setAnalytics = (code, pattern, type, isUsed) ->
  cleanAnalytics()

  if(isUsed)
    $.ajax({
      url: '/account/analytics',
      data: { code: code, pattern: pattern, type: type },
      dataType: 'json',
      type: 'GET',
      beforeSend: () ->
        $('#analytic .fields, .no_compta_analysis, .with_default_analysis, .with_compta_analysis, .analytic_resume_box, .help-block').hide()
        $('.analytic_loading').show()
      success: (data) ->
        window.analytics = data['analytics']

        if(window.analytics != undefined && window.analytics != null && window.analytics.length > 0)
          analytic_options = '<option selected value>Sélectionnez une analyse</option>'
          for i in [0...window.analytics.length] by 1
            analytic_options = analytic_options + "<option value='" + window.analytics[i]['name'] + "'>" + window.analytics[i]['name'] + "</option>"
          $('.analytic_name').html(analytic_options)

          $('#analytic .fields, .with_compta_analysis, .analytic_resume_box, .help-block').show()
          setDefaultAnalytics(data['defaults'])

          if(window.analytic_target_form == '#fileupload')
            $("#uploadDialog .analytic_resume_box").html(getAnalyticsResume())
        else
          $('.no_compta_analysis').show()
          $('.with_compta_analysis, .analytic_resume_box, .help-block').hide()

        $('.analytic_loading').hide()
      error: (data) ->
        $('#analytic .fields, .analytic_loading, .with_default_analysis, .with_compta_analysis, .analytic_resume_box, .help-block').hide()
        $('.no_compta_analysis').show()
    })
  else
    $('#analytic .fields, .analytic_loading, .with_default_analysis, .with_compta_analysis, .analytic_resume_box, .help-block').hide()
    $('.no_compta_analysis').show()

byAnalyticId = (element) ->
  return element['name'] == this.val()

handleAnalysisChange = () ->
  current_analytic = $(this)
  number = current_analytic.data('analytic-number')

  $('#analytic_'+number+'_group .analytic_axis').html('')
  $('#analytic_'+number+'_group .analytic_ventilation').val(0).change()
  $('#analytic_'+number+'_group .analytic_box').addClass('hide')
  $('#analytic_'+number+'_group .analytic_axis_group').addClass('hide')

  $("#{window.analytic_target_form} .analytic_hidden_group_#{number} .hidden_analytic_axis").val('')

  if(window.analytics != undefined && window.analytics != null && current_analytic.val() != '')
    $("#analytic_#{number}_group .analytic_box").removeClass('hide')
    analytic = window.analytics.find(byAnalyticId, current_analytic)

    references = null
    if window.defaults != undefined && window.defaults != null && window.defaults != ''
      references = window.defaults["a#{number}_references"]

    for i in [1..3] by 1
      for j in [1..3] by 1
        num               = "#{number}#{j}"
        axis_name         = "axis#{i}"
        axis              = $('#h_analytic_'+num+'_'+axis_name)
        axis_group        = $('#analytic_'+num+'_'+axis_name+'-group')
        label_axis_group  = $('#analytic_'+num+'_'+axis_name+'-group label')
        hidden_axis = $("#{window.analytic_target_form} .analytic_#{num}_#{axis_name}")

        if(analytic[axis_name] != undefined && analytic[axis_name] != null)
          sections = analytic[axis_name]['sections']
          selected = a_axis = ''

          if references != undefined && references != null && references != ''
            a_axis = references[j-1]["axis#{i}"]
          
          if a_axis != undefined && a_axis != null && a_axis != ''
            selected = 'selected'  
          axis_options = "<option #{selected} value>Sélectionnez une section</option>"

          for s in [0...sections.length] by 1
            selected = ''
            if a_axis == sections[s]['code']
              selected = 'selected'
            axis_options = axis_options + "<option #{selected} value='" + sections[s]['code'] + "'>" + sections[s]['description'] + "</option>"

          axis.html(axis_options)
          label_axis_group.html("Axe: <i style='font-weight: normal'>#{analytic[axis_name]['name']}</i>")
          axis_group.removeClass('hide')

          # axis.chosen({ search_contains: true, allow_single_deselect: true, no_results_text: 'Aucun résultat correspondant à' })
          # axis.trigger('chosen:updated')

          hidden_axis.val(axis.val())

    $("#analytic_#{number}_group .analytic_box").addClass('hide')
    $("#analytic_#{number}_group #analytic_parent_box#{number}").removeClass('hide')

handleAnalysisSelect = () ->
  target = $(this).data('target')
  $(window.analytic_target_form + ' .' + target).val( $(this).val() )

handleAnalaysisVentilation = (elem) ->
  number = $(this).data('ventilation-number')
  target = $(this).data('target')

  $(window.analytic_target_form + ' .' + target).val( $(this).val() )

  total_ventilation = 0
  $(".analytic_ventilation_group_#{number}").each( () -> total_ventilation += parseFloat($(this).val()) )
  $("#total_ventilation_#{number}").html(" Total Ventilation: #{total_ventilation}%")

  if(total_ventilation == 100)
    $("#total_ventilation_#{number}").addClass('green')
  else
    $("#total_ventilation_#{number}").removeClass('green')

toogleSectionGroup = () ->
  number = $(this).data('group-number')
  if ($("#analytic_parent_box#{number}").is(":visible"))
    $("#analytic_parent_box#{number}").slideUp('fast')
  else
    $("#analytic_parent_box#{number}").slideDown('fast')

jQuery ->
  window.analytic_target_form = null
  window.analytics = null
  window.setAnalytics = setAnalytics
  window.cleanAnalytics = cleanAnalytics
  window.getAnalyticsResume = getAnalyticsResume

  if $('#customers.journal.analytics').length > 0
    window.analytic_target_form = '#compta_analytics_journal'
    setAnalytics($('#customer_code').val(), $('#journal_name').val(), 'journal', true)
  
  $('.analytic_name').on('change', handleAnalysisChange)
  $('.analytic_ventilation').on('change', handleAnalaysisVentilation)
  $('.analytic_select').on('change', handleAnalysisSelect)
  $('.analytic_group .section_map').on('click', toogleSectionGroup)
  
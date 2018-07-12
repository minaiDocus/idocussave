class Idocus.Models.Common
  constructor: ()->
    this

  sort_array_models_by: (property) ->
    return (a,b) ->
      a_val = a.get(property).toLowerCase()
      b_val = b.get(property).toLowerCase()
      result = (a_val < b_val) ? -1 : (a_val > b_val) ? 1 : 0
      return result

  serialize_form_json: (form)->
    data = form.serializeArray()
    result = {}
    for obj in data
      if obj.name.match(/\[\]/)
        obj_index = obj.name.replace(/\[\]/g, '')
        obj_val = eval("result.#{obj_index}")
        if  obj_val != '' && obj_val != undefined && obj_val != null
          if obj.value != undefined && obj.value != '' && obj.value != null
            eval("result.#{obj_index}.push('#{obj.value}')")
        else
          if obj.value != undefined && obj.value != '' && obj.value != null
            Object.assign(result, result, {"#{obj_index}": [obj.value]})
      else
        if obj.value != undefined && obj.value != '' && obj.value != null
          Object.assign(result, result, {"#{obj.name}": obj.value})
    result

  fields_constructor: (fields)->
    html = ''
    for field in fields
      class_required = abbr_required = ''
      if field.required
        class_required = 'required'
        abbr_required = '<abbr title="champ requis">*</abbr>'

      field_input = '<input class="field '+class_required+'" style="outline: medium none currentcolor;" id="field_'+field.name+'" name="'+field.name+'" type="'+field.type+'" value="'+(field.value || '')+'">'

      if field.type == "list"
        options = ""
        for option in field.values
          selected = ''
          if option.value == field.selected
            selected = 'selected'
          options += "<option value='#{option.value}' #{selected}>#{option.label}</options>"

        field_input = '<select class="select field '+class_required+'" style="outline: medium none currentcolor; width: 263px!important;" id="field_'+field.name+'" name="'+field.name+'">'+options+'</select>'

      html += '<div class="control-group '+class_required+' field_parent">
                <label class="'+class_required+' control-label" for="field_'+field.name+'">
                  '+abbr_required+' '+field.label+'
                </label>
                <div class="controls">
                  '+field_input+'
                </div>
              </div>'
    html

  valid_fields: (el)->
    valid = true
    el.find('.hint_error').remove()
    el.find('.field_parent').removeClass('error')
    el.find('.field.required').each((index)->
      if $(this).val() == '' || $(this).val() == undefined
        valid = false
        $(this).after('<span class="help-inline hint_error">champ obligatoire</span>')
        $(this).parent().parent('.field_parent').addClass('error')
    )
    valid

  action_loading: (el, load)->
    if load
      el.find('.form-actions .actions').css(display: 'none')
      el.find('.form-actions .actions').after('<div class="feedback pull-left active"></div>')
    else
      el.find('.form-actions .actions').css(display: 'block')
      el.find('.form-actions .feedback').remove()

  go_to_step2: (connector_info )->
    $('#budgea_sync #section1 #section11').css('display', 'none')
    $('#budgea_sync #section1 #section12').css('display', '')
    $('#budgea_sync #section1').css('display', '')
    $('#budgea_sync #section2').css('display', 'none')

    if @step2_view == undefined
      @step2_view = new Idocus.Views.RetrieversStep2(el: $('#budgea_additionnal_fields'))

    @step2_view.generate_additionnal_fields(connector_info, connector_info.additionnal_fields)

  go_to_step3: (connector_info)->
    $('#budgea_sync #section1').css('display', 'none')
    $('#budgea_sync #section2').css('display', '')

    if @step3_view == undefined
      @step3_view = new Idocus.Views.RetrieversStep3(el: $('#budgea_bank_accounts'))

    @step3_view.load_connector_info(connector_info)
    @step3_view.render()

  setCache: (name, value, lifeTime)->
    localStorage[name] = JSON.stringify({ dataSet: value, timeSet: new Date().getTime(), lifeTime: (lifeTime || 30) }) #lifeTime in minutes

  getCache: (name)->
    if localStorage[name] == undefined || localStorage[name] == '' || localStorage[name] == null
      console.log 'init'
      return ''
    else
      dataCache = JSON.parse(localStorage[name])
      dataSet = dataCache.dataSet
      lifeTime = dataCache.lifeTime
      timeSet = dataCache.timeSet

      if (dataSet == undefined || dataSet == '' || dataSet == null) || (lifeTime == undefined || lifeTime == '' || lifeTime == null)
        return ''
      else
        endTime = new Date().getTime()
        timeDiff = ((endTime - timeSet) / 1000) / 60 #timeDiff in minutes

        if timeDiff >= lifeTime
          console.log 'reset'
          return ''
        else
          console.log 'cache'
          return dataSet

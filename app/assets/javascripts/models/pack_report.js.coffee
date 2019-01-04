class Idocus.Models.PackReport extends Backbone.Model

  urlRoot: 'pack_reports'

  deliver: ->
    $.ajax
      url: "#{@urlRoot}/#{@get('id')}/deliver"
      type: 'POST'
      data: ''
      datatype: 'json'

  delivery_message: ->
    mess = null
    if(@get('delivery_message'))
      mess = JSON.parse(@get('delivery_message'))
    if mess && @get('user_software') == 'Ibiza'
      return (mess.ibiza || null)
    else if mess && @get('user_software') == 'Exact Online'
      return (mess.exact_online || null)
    else
      return null
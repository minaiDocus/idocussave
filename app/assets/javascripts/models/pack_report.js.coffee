class Idocus.Models.PackReport extends Backbone.Model

  urlRoot: 'pack_reports'

  deliver: ->
    $.ajax
      url: "#{@urlRoot}/#{@get('id')}/deliver"
      type: 'POST'
      data: ''
      datatype: 'json'

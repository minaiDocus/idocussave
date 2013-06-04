class Idocus.Models.Preseizure extends Backbone.Model

  urlRoot: 'preseizures'

  schema:
    date:
      type: "Text", title: "Date"
    deadline_date:
      type: "Text", title: "Echéance"
    third_party:
      type: "Text", title: "Tiers"
    piece_number:
      type: "Text", title: "Numéro de pièce"
    amount:
      type: "Number", title: "Montant d'origine"
    currency:
      type: "Text", title: "Devise"
    convertion_rate:
      type: "Text", title: "Taux de conversion"
    observation:
      type: "TextArea", title: "Remarque"

  toJSON: ->
    preseizure: _.clone( @attributes )

  description: ->
    results = []
    obj = @
    @get('description_keys').forEach (e, i, a) ->
      results.push obj.get(e)
    results = _.compact(results)
    results.join(@get('description_separator'))

  deliver: ->
    $.ajax
      url: "#{@urlRoot}/#{@get('id')}/deliver"
      type: 'POST'
      data: ''
      datatype: 'json'

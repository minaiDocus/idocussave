class Idocus.Models.Preseizure extends Backbone.Model

  urlRoot: 'preseizures'

  schema:
    date:
      type: "Text", title: "Date"
    deadline_date:
      type: "Text", title: "Echéance"
    third_party:
      type: "Text", title: "Tiers"
    operation_label:
      type: "TextArea", title: "Libellé de l'opération"
    piece_number:
      type: "Text", title: "Numéro de pièce d'origine"
    amount:
      type: "Text", title: "Montant d'origine", validators: [/^-?\d+(\.\d{1,2})?$/]
    currency:
      type: "Text", title: "Devise"
    conversion_rate:
      type: "Text", title: "Taux de conversion"
    observation:
      type: "TextArea", title: "Remarque"

  toJSON: ->
    preseizure: _.clone( @attributes )

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

  description: ->
    results = []
    obj = @
    @get('description_keys').forEach (e, i, a) ->
      results.push obj.get(e)
    results = _.compact(results)
    text = results.join(@get('description_separator'))
    if text == ""
      if @get('third_party') != null
        @get('third_party')
      else if @get('operation_label') != null
        @get('operation_label')
      else
        '-'
    else
      text

  deliver: ->
    $.ajax
      url: "#{@urlRoot}/#{@get('id')}/deliver"
      type: 'POST'
      data: ''
      datatype: 'json'

  has_link: ->
    @get('type') != 'FLUX'

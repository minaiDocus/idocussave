class Idocus.Models.PreseizureAccount extends Backbone.Model

  urlRoot: 'preseizure_accounts'

  parse: (resp) ->
    if resp.entries
      resp.entries = new Idocus.Collections.PreseizureEntries(resp.entries);
    resp

  schema:
    type:
      type: "Select", title: "Type", options: [{ val: 1, label: 'TTC' }, { val: 2, label: 'HT' }, { val: 3, label: 'TVA' }]
    number:
      type: "Text", title: "Numéro de compte"
    lettering:
      type: "Text", title: "Lettrage"

  toJSON: ->
    account:
      type: @get('type')
      number: @get('number')
      lettering: @get('lettering')
      entries_attributes: @get('entries')

  typeName: ->
    if parseInt(@get('type')) == 1
      'TTC'
    else if parseInt(@get('type')) == 2
      'HT'
    else if parseInt(@get('type')) == 3
      'TVA'
    else
      ''
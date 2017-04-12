class Idocus.Models.PreseizureEntry extends Backbone.Model

  urlRoot: 'preseizure_entries'

  schema:
    type:
      type: "Select", title: "Type", options: [{ val: 1, label: 'Débit' }, { val: 2, label: 'Crédit' }]
    amount:
      type: "Text", title: "Montant", validators: [/^\d+(\.\d{1,2})?$/]

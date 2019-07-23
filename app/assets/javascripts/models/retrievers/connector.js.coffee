class Idocus.Models.Connector extends Backbone.Model
  initialize: () ->
    @common = new Idocus.Models.Common()
    this

  parse_urls: ()->
    urls = @get("urls")
    html = '<ul>'

    for u in urls
      html += '<li><a href="'+u+'" target="_blank">'+u+'</a></li>'

    html += '</ul>'

  set_contact_values: ()->
    contact = Idocus.budgeaApi.user_profiles.contact || {}
    $('#connector_fields #field_contact_field_society').val(contact.society || $('#contact_company').val() || '')
    $('#connector_fields #field_contact_field_name').val(contact.name || $('#contact_name').val() || '')
    $('#connector_fields #field_contact_field_first_name').val(contact.first_name || $('#contact_first_name').val() || '')

  contact_fields: ()->
    fields = [
                { type: "text", name: "contact_field_society", label: "Nom de la société", class: 'contact_fields', value: '' },
                { type: "text", name: "contact_field_name", label: "Nom du dirigeant", class: 'contact_fields', value: '' },
                { type: "text", name: "contact_field_first_name", label: "Prénom du dirigeant", class: 'contact_fields', value: '' }
             ]
    @common.fields_constructor(fields)

  information_fields: ()->
    fields = @get('fields') || []

    ##Add field exception for Paypal API REST
    if(@get('name') == 'Paypal REST API')
      fields = fields.concat({ label: '', name: 'paypal_oauth', value: 'true', regex: null, required: false, type: "oauth" })

    if Idocus.new_connector
      for f in fields
        Object.assign(f, f, {required: true})

    @common.fields_constructor(fields)

  basic_fields: ()->
    fields = [{ type: "text", name: "ido_custom_name", label: "Nom personnalisé", required: true, value: $('#retriever_custom_name').val() || @get('name') }]
    if @get('capabilities').includes('document')
      journals = [':']
      if $('#retriever_journals').val()
        journals = $('#retriever_journals').val().split("_")

      journal_options = []
      for j in journals
        journal_options.push({value: j.split(':')[0], label: j.split(':')[1]})

      fields.push({ type: "list", name: "ido_journal", label: "Journal", required: true, values: journal_options, selected: $('#retriever_journal_id').val() || '' })
    @common.fields_constructor(fields)

  get_type: () ->
    capabilities = @get('capabilities')
    text = []

    if capabilities.includes('bank')
      text.push("Opérations bancaires")
    if capabilities.includes('document')
      text.push("Documents (factures)")

    text.join(" et ")
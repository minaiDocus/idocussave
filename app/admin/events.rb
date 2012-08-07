# -*- encoding : UTF-8 -*-
ActiveAdmin.register Event do
  filter :title,  as: String, label: 'Titre'
  
  actions :index
  
  config.sort_order = 'created_at_desc'
  
  index do
    column 'Date de création', sortable: :created_at do |event|
      l(event.created_at)
    end
    column 'Identifiant', sortable: :user do |event|
      link_to [event.user.code,event.user.company,event.user.name].compact.join(' - '), [:admin, event.user]
    end
    column 'Titre', sortable: :title do |event|
      event.title
    end
    column 'Prix', sortable: :price_in_cents_wo_vat do |event|
      format_price(event.price_in_cents_wo_vat) + ' € HT - ' + format_price(event.price_in_cents_w_vat) + ' € TTC'
    end
    column 'Type', sortable: :type do |event|
      if event.type_number
        'Ok'
      elsif event.type_number == 1
        'Débit'
      elsif event.type_number == 2
        'Crédit'
      else
        'Inconnu'
      end
    end
  end
  
end

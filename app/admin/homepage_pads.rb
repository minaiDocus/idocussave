# -*- encoding : UTF-8 -*-
ActiveAdmin.register Homepage::Pad do
  menu :parent => "Homepage"

  actions :all, except: [:show]
  
  filter :caption, as: 'string'
  
  index do
    column :position
    column 'Nom', sortable: :caption do |pad|
      pad.caption
    end
    column 'est visible ?', sortable: :is_invisible do |pad|
      pad.is_invisible ? 'Non' : 'Oui'
    end
    default_actions
  end
  
  form :partial => "form"
  
end

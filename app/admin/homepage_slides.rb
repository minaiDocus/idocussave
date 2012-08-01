ActiveAdmin.register Homepage::Slide do
  menu :parent => "Homepage"

  actions :all, except: [:show]
  filter :caption, as: 'string'
  
  index do
    column :position
    column 'Nom', sortable: :position do |slide|
      slide.name
    end
    column 'est visible ?', sortable: :is_invisible do |slide|
      slide.is_invisible ? 'Non' : 'Oui'
    end
    default_actions
  end
  
  form :partial => "form"
end

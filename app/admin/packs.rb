# -*- encoding : UTF-8 -*-
ActiveAdmin.register Pack do
  filter :name, as: :string, label: 'Nom'
  
  index do
    column 'Créé le', sortable: :created_at do |pack| 
      pack.created_at
    end
    column 'Nom', sortable: :name do |pack|
      pack.name
    end
    column 'Nombre de documents', :documents do |pack|
      pack.documents.without_original.count
    end
  end 
  
end

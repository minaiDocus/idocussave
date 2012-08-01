# -*- encoding : UTF-8 -*-
ActiveAdmin.register Homepage::Base do
  menu :parent => "Homepage"

  filter :name, as: 'string'
  
  index do
    column "name" do |base|
      link_to base.name, admin2_homepage_basis_path(base)
    end
    default_actions
  end
  
  show do |base|
    attributes_table do
      row "Nom" do
        base.name
       end
      row "Style" do
        base.style
      end
      row "Contenu" do
        base.content
      end
      row "Méta-description" do
        base.meta_description
      end    
    end
  end
  
  form partial: "form"
  
end

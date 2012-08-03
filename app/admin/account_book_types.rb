# -*- encoding : UTF-8 -*-
ActiveAdmin.register AccountBookType do
  filter :name, as: 'string'
  config.sort_order = "owner_asc"
  
  index do
     column :position,sortable: :position do |account_book_type|
       account_book_type.position
     end
     column 'Prescripteur', sortable: :owner do |account_book_type|
       account_book_type.owner.try(:email)
     end
     column 'Nom', sortable: :name do |account_book_type| 
       account_book_type.name
     end
     column :description, sortable: :description do |account_book_type|
       account_book_type.description
     end  
  end
end


# -*- encoding : UTF-8 -*-
ActiveAdmin.register User do
  actions :all, except: [:destroy]

  filter :company, as: 'string', label: 'Société'
  filter :code, as: 'string'
  filter :first_name, as: 'string', label: 'Prénom'
  filter :last_name, as: 'string', label: 'Nom'
  filter :email, as: 'string', label: 'E-mail'

  index do
    column 'Date de création', sortable: true do |user|
      user.created_at
    end
    column :email
    column 'Société / Code' do |user|
      [user.company, user.code].join(' ')
    end
    column 'Est confirmé ?' do |user|
      user.confirmed? ? 'oui' : 'non'
    end
    default_actions
  end

  show do |user|
    attributes_table do
      row :created_at
      row :name
      row :code
      row :company
      row 'Acitf ?' do |user|
        user.inactive_at.nil? ? 'Oui' : 'Non'
      end
      row :is_admin
      row :is_prescriber
      row :use_debit_mandate
    end
  end

  form :partial => "form"
end

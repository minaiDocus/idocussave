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

  form do |f|
    f.inputs 'Informations' do
      f.input :email, label: 'E-mail'
      f.input :first_name, label: 'Prénom'
      f.input :last_name, label: 'Nom'
      f.input :code, label: 'Code client'
      f.input :company, label: 'Société'
    end

    f.inputs 'Autorisation' do
      f.input :is_admin, as: :boolean, label: 'Est administrateur ?'
    end
    f.buttons
  end
end

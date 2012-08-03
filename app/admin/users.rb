# -*- encoding : UTF-8 -*-
ActiveAdmin.register User do
  actions :all, except: [:destroy]

  filter :company, as: 'string', label: 'Société'
  filter :code, as: 'string'
  filter :first_name, as: 'string', label: 'Prénom'
  filter :last_name, as: 'string', label: 'Nom'
  filter :email, as: 'string', label: 'E-mail'
  
  config.sort_order= "created_at_desc"

  index do
    column 'Date de création', sortable: :created_at do |user|
      l(user.created_at, format: :short)
    end
    column :email
    column 'Société / Code', sortable: :code do |user|
      [user.company, user.code].join(' ')
    end
    column 'Est confirmé ?' do |user|
      user.confirmed? ? 'oui' : 'non'
    end
    default_actions
  end

  show title: :name do |user|
    div class: 'panel' do
      h3 'Informations'
      div class: 'panel_contents' do
         div class: 'attributes_table user' do
            table do
              tbody do
                tr do
                  th 'Date d\'inscription'
                  td user.created_at
                end
                tr do
                  th 'Nom complet'
                  td [user.first_name,user.last_name].join(' ')
                end
                tr do
                  th 'Code client'
                  td user.code
                end
                tr do
                  th 'Société'
                  td user.company
                end
                tr do
                  th 'Actif ?'
                  td user.inactive_at.nil? ? 'Oui' : 'Non'
                end
                tr do
                  th 'Est administrateur ?'
                  td user.is_admin ? 'Oui' : 'Non'
                end
                tr do
                  th 'Est prescripteur ?'
                  td user.is_prescriber ? 'Oui' : 'Non'
                end
                tr do
                  th 'Mode de paiement'
                  td user.use_debit_mandate ? 'Prélèvement' : 'Prépayé'
                end
              end
            end
         end
      end
    end

    div class: 'panel' do
      h3 'Adresses'
      div class: 'panel_contents' do
        div class: 'attributes_table user' do
          table do
            tbody do
              tr do
                th 'Facturation'
                td render partial: 'address', locals: { address: user.billing_address }
              end
              tr do
                th 'Retour'
                td render partial: 'address', locals: { address: user.shipping_address }
              end
            end
          end
        end
      end
    end
  end

  collection_action :search_by_code, :method => :get do
    tags = []
    if params[:q].present?
      users = User.where(code: /.*#{params[:q]}.*/i)
      users = users.prescribers if params[:prescriber].present?
      users.each do |user|
        tags << {id: user.id, name: user.code}
      end
    end

    respond_to do |format|
      format.json{ render json: tags.to_json, status: :ok }
    end
  end

  form partial: "form"
end

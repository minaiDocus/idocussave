# -*- encoding : UTF-8 -*-
ActiveAdmin.register FileSendingKit do
  filter :title, as: String, label: 'Titre'

  config.sort_order= "position_asc"

  index do
    column :position
    column 'Date de création', sortable: :created_at do |file_sending_kit|
      l(file_sending_kit.created_at)
    end
    column 'Titre', sortable: :title do |file_sending_kit|
      file_sending_kit.title
    end
    column 'Prescripteur', sortable: :title do |file_sending_kit|
      [file_sending_kit.user.try(:company), file_sending_kit.user.try(:code)].join(' - ')
    end
    default_actions
  end

  show title: :title do
    render 'show'
  end

  form partial: 'form'

  member_action :generate, :method => :post do
    clients_data = []
    @file_sending_kit = FileSendingKit.find(params[:id])
    @file_sending_kit.user.clients.asc(:code).asc(:email).each do |client|
      value = params[:users][client.id.to_s][:is_checked] rescue nil
      if value == 'true'
        clients_data << { user: client, start_month: params[:users][client.id.to_s][:start_month].to_i, offset_month: params[:users][client.id.to_s][:offset_month].to_i }
      end
    end
    FileSendingKitGenerator::generate(clients_data, @file_sending_kit)
    flash[:notice] = 'Généré avec succès.'
    session[:file_sending_kit] = { is_generated: true }
    redirect_to action: 'show'
  end
end

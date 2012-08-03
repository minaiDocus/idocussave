# -*- encoding : UTF-8 -*-
ActiveAdmin.register ReminderEmail do
  filter :name, as: :string, label: 'Nom'
  config.sort_order= "name_asc"
  
  index do
    column 'Nom', sortable: :name do |reminder_email|
      reminder_email.name
    end
    column 'Client', sortable: :user do |reminder_email|
      reminder_email.user.email
    end
    column 'Date de livraison', sortable: :delivery_day do |reminder_email|
      reminder_email.delivery_day
    end
    column 'Délivré(s) / Traité(s) / Total', sortable: :reminder_email do |reminder_email|  
      [reminder_email.delivered_users.count, reminder_email.processed_users.count,reminder_email.user.clients.active.count].join(' /')
    end
    default_actions
  end
  form partial: "form"
end

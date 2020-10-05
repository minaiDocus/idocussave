# -*- encoding : UTF-8 -*-
class Dematbox < ApplicationRecord
  belongs_to :user
  has_many :services, class_name: 'DematboxSubscribedService', inverse_of: :dematbox


  scope :configured,     -> { where(is_configured: true) }
  scope :not_configured, -> { where(is_configured: false) }


  def journal_names
    user.account_book_types.order(name: :asc).map(&:name)
  end


  def build_services
    all_groups   = DematboxService.groups.order(name: :asc).to_a
    all_services = DematboxService.services.order(name: :asc).to_a

    current_group  = all_groups.shift
    previous_group = all_groups.shift

    if current_group && previous_group
      current_group_params  = current_group.to_params('Période Actuelle').merge(services: { service: [] })
      previous_group_params = previous_group.to_params('Période Précédente').merge(services: { service: [] })

      journal_names.each do |journal_name|
        current_service  = all_services.shift
        previous_service = all_services.shift

        if current_service && previous_service
          current_group_params[:services][:service] << current_service.to_params(journal_name)
          previous_group_params[:services][:service] << previous_service.to_params(journal_name)
        end
      end

      [current_group_params, previous_group_params]
    end
  end


  def subscribe(pairing_code = nil)
    update_attribute(:beginning_configuration_at, Time.now)

    _services = build_services

    result = DematboxApi.subscribe(user.code, _services, pairing_code)

    update_attribute(:beginning_configuration_at, nil) unless beginning_configuration_at.nil?

    if result =~ /\A200\s*:\s*OK\z/
      update_attribute(:is_configured, true)

      set_services(_services)
    else
      result
    end
  end


  def set_services(_services)
    services.destroy_all
    _services.each do |group|
      group[:services][:service].each do |service|
        new_service                       = DematboxSubscribedService.new
        new_service.name                  = service[:service_name]
        new_service.pid                   = service[:service_id]
        new_service.group_name            = group[:service_name]
        new_service.group_pid             = group[:service_id]
        new_service.is_for_current_period = group[:service_name] == 'Période Actuelle'

        services << new_service
      end
    end

    save
  end


  def to_s
    "Dematbox #{user.code}\n" + services.order(name: :asc, group_name: :asc).map(&:to_s).join("\n")
  end


  def unsubscribe
    result = DematboxApi.unsubscribe(user.code)

    destroy if result =~ /\A200\s*:\s*OK\z/
  end
end

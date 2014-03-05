# -*- encoding : UTF-8 -*-
class Dematbox
  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :user
  embeds_many :services, class_name: 'DematboxSubscribedService', inverse_of: :dematbox

  field :beginning_configuration_at, type: Time

  def journal_names
    user.account_book_types.asc(:name).map(&:name)
  end

  def build_services
    _services = {}
    current_services = DematboxService.current.services.asc(:name).entries
    previous_services = DematboxService.previous.services.asc(:name).entries
    journal_names.each do |journal_name|
      current_service = current_services.shift
      previous_service = previous_services.shift
      if current_service && previous_service
        group = current_service.group
        if group
          unless _services["group_#{group.id}"]
            _services["group_#{group.id}"] = group.to_params.merge({ services: { service: [] } })
          end
          _services["group_#{group.id}"][:services][:service] << current_service.to_params(journal_name)
        else
          _services["service_#{current_service.id}"] = current_service.to_params(journal_name)
        end

        group = previous_service.group
        if group
          unless _services["group_#{group.id}"]
            _services["group_#{group.id}"] = group.to_params.merge({ services: { service: [] } })
          end
          _services["group_#{group.id}"][:services][:service] << previous_service.to_params(journal_name)
        else
          _services["service_#{previous_service.id}"] = previous_service.to_params(journal_name)
        end
      end
    end
    _services.values
  end

  def async_subscribe(pairing_code=nil)
    update_attribute(:beginning_configuration_at, Time.now)
    delay(priority: 1).subscribe(pairing_code)
  end

  def subscribe(pairing_code=nil)
    _services = build_services
    result = DematboxApi.subscribe(user.code, _services, pairing_code)
    update_attribute(:beginning_configuration_at, nil) unless beginning_configuration_at.nil?
    if result.match(/^200\s*:\s*OK$/)
      services.destroy_all
      _services.each do |_service|
        if _service[:type] == 'service'
          service = services.build
          service.name = _service[:service_name]
          service.pid = _service[:service_id]
        elsif _service[:type] == 'group'
          _service[:services][:service].each do |__service|
            service = services.build
            service.name = __service[:service_name]
            service.pid = __service[:service_id]
            service.group_name = _service[:service_name]
            service.group_pid = _service[:service_id]
            service.is_for_current_period = DematboxService.where(pid: service.group_pid).first.is_for_current_period
          end
        end
      end
      save
    else
      result
    end
  end

  def to_s
    "Dematbox #{user.code}\n" + services.asc([:name, :group_name]).map(&:to_s).join("\n")
  end

  def unsubscribe
    result = DematboxApi.unsubscribe(user.code)
    if result.match(/^200\s*:\s*OK$/)
      destroy
    end
  end
end

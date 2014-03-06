# -*- encoding : UTF-8 -*-
class DematboxService
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name,  type: String
  field :pid,   type: String
  field :type,  type: String
  field :state, type: String,  default: 'unknown'

  validates_presence_of :name, :pid, :type, :state

  scope :services, where: { type: 'service' }
  scope :groups,   where: { type: 'group' }

  state_machine initial: :unknown do
    state :unknown
    state :verified
    state :not_valid

    event :verified do
      transition [:unknown, :not_valid] => :verified
    end

    event :not_valid do
      transition [:unknown, :verified] => :not_valid
    end
  end

  def self.load_from_external
    services = []
    DematboxApi::services.each do |raw_service|
      unless raw_service[:service_id] == DematboxServiceApi.config.service_id.to_s
        _attributes = {
          name: raw_service[:service_name],
          pid:  raw_service[:service_id],
          type: raw_service[:type]
        }
        service = DematboxService.where(pid: raw_service[:service_id]).first
        if service
          service.update_attributes(_attributes)
        else
          service = DematboxService.create(_attributes)
        end
        service.verified unless service.verified?
        services << service
      end
    end
    removed_services = DematboxService.all.entries - services
    removed_services.each do |removed_service|
      removed_service.not_valid unless removed_service.not_valid?
    end
    services
  end

  def to_params(name=self.name)
    {
      type:         type,
      service_name: name,
      service_id:   pid
    }
  end
end

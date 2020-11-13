class Dematbox::Refresh
  # Call Dematbox API to retrieve services
  # Updates service to verify if OK or invalidate if NOK
  def self.execute
    services = []

    DematboxApi.services.each do |raw_service|
      next if raw_service[:service_id] == DematboxServiceApi.config.service_id.to_s

      _attributes = {
        type: raw_service[:type],
        pid:  raw_service[:service_id],
        name: raw_service[:service_name],
      }

      service = DematboxService.where(pid: raw_service[:service_id]).first

      if service
        service.update(_attributes)
      else
        service = DematboxService.create(_attributes)
      end

      service.verified unless service.verified?

      services << service
    end

    removed_services = DematboxService.all - services

    removed_services.each do |removed_service|
      removed_service.not_valid unless removed_service.not_valid?
    end

    services
  end
end

class UpdateConnectorsList
  def self.execute
    log = Logger.new("#{Rails.root}/log/#{Rails.env}.log")
    new_connectors = []

    BudgeaConnector.flush_all_cache
    BudgeaConnector.all.each do |budgea_connector|
      unless budgea_connector['name'] == 'Connecteur de test'
        unless Connector.where(name: budgea_connector['name']).first
          connector = Connector.new
          connector.name         = budgea_connector['name']
          connector.budgea_id    = budgea_connector['id']
          connector.apis         = ['budgea']
          connector.active_apis  = ['budgea']
          connector.capabilities = budgea_connector['capabilities']
          connector.urls         = budgea_connector['urls']
          connector.combined_fields = {}
          budgea_connector['fields'].each do |field|
            connector.combined_fields[field['name']] = field.slice(:label, :type, :regex, :values)
            connector.combined_fields[field['name']]['budgea_name'] = field['name']
          end
          new_connectors << connector if connector.save
        end
      end
    end

    new_connectors.each do |new_connector|
      log.info "Adding new connector : #{new_connector.name}"
    end
  end
end

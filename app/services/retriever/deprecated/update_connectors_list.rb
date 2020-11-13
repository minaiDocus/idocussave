class Retriever::UpdateConnectorsList
  def self.execute
    return false
    #Not used anymore just keep the code in case
    Retriever::BudgeaConnector.flush_all_cache
    Retriever::BudgeaConnector.all.each do |budgea_connector|
      next if Rails.env.production? && budgea_connector['name'] == 'Connecteur de test'

      connector = Connector.find_or_initialize_by(budgea_id: budgea_connector['id'])
      connector.name            = budgea_connector['name']
      connector.apis            = ['budgea']
      connector.active_apis     = ['budgea']
      connector.capabilities    = budgea_connector['capabilities']
      connector.urls            = budgea_connector['urls']
      connector.combined_fields = {}
      budgea_connector['fields'].each do |field|
        connector.combined_fields[field['name']] = field.slice(:label, :type, :regex, :values)
        connector.combined_fields[field['name']]['budgea_name'] = field['name']
      end

      changes = connector.changes
      connector.save

      if connector.persisted?
        # Because activerecord hash change detection is dumb !
        changes = changes.select { |_, v| v.first != v.last }
        System::Log.info('processing', "[CONNECTOR UPDATED] #{connector.name} - #{connector.id} : #{changes}") if changes.present?
      else
        System::Log.info('processing', "[CONNECTOR ADDED] #{connector.name} - #{connector.id}")
      end
    end
    true
  end
end

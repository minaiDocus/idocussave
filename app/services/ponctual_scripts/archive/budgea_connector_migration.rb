class PonctualScripts::Archive::BudgeaConnectorMigration
  def self.execute
    retrievers = Retriever.all
    retrievers.each do |retriever|
      connector_id = retriever.try(:connector).try(:budgea_id)
      retriever.update(budgea_connector_id: connector_id) unless retriever.budgea_connector_id.present?
      retriever.update(service_name: retriever.try(:connector).try(:name)) if retriever.try(:connector).try(:name).present?
    end
  end
end
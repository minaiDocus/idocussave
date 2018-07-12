class BudgeaConnectorMigration
  def self.execute
    retrievers = Retrievers.all
    retrievers.each do |retriever|
      connector_id = retriever.try(:connector).try(:budgea_id)
      retriever.update(budgea_connector_id: connector_id)
    end
  end
end
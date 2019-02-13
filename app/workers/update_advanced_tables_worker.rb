class UpdateAdvancedTablesWorker
  include Sidekiq::Worker

  def perform()
    UniqueJobs.for "update_advanced_tables" do
      UpdateAdvancedTables::Preseizures.execute
    end
  end
end

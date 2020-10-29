class Retriever::UpdateConnectorsListWorker
  include Sidekiq::Worker
  sidekiq_options queue: :default

  def perform
    UniqueJobs.for 'UpdateConnectorsList' do
      Retriever::UpdateConnectorsList.execute
    end
  end
end

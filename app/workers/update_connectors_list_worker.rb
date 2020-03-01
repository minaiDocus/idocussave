class UpdateConnectorsListWorker
  include Sidekiq::Worker
  sidekiq_options queue: :default

  def perform
    UniqueJobs.for 'UpdateConnectorsList' do
      UpdateConnectorsList.execute
    end
  end
end

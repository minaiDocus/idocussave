class UpdateConnectorsListWorker
  include Sidekiq::Worker
  sidekiq_options queue: :default

  def perform
    UpdateConnectorsList.execute
  end
end

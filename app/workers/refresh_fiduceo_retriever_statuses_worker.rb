class RefreshFiduceoRetrieverStatusesWorker
  include Sidekiq::Worker
  sidekiq_options queue: :default, retry: :false, unique: :until_and_while_executing

  def perform
    FiduceoUpdateRetrieverState.refresh_all
  end
end
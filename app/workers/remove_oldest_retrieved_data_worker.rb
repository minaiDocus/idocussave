class RemoveOldestRetrievedDataWorker
  include Sidekiq::Worker

  def perform
    RetrievedData.remove_oldest
  end
end

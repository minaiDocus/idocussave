class RemoveOldestRetrievedDataWorker
  include Sidekiq::Worker
  sidekiq_options queue: :default, unique: :until_and_while_executing

  def perform
    RetrievedData.remove_oldest
  end
end

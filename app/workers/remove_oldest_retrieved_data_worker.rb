class RemoveOldestRetrievedDataWorker
  include Sidekiq::Worker

  def perform
	UniqueJobs.for 'RemoveOldestRetrievedData' do
      RetrievedData.remove_oldest
    end
  end
end

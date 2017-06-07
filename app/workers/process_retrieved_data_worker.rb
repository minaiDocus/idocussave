class ProcessRetrievedDataWorker
  include Sidekiq::Worker
  sidekiq_options retry: false

  def perform(retrieved_data_id)
    UniqueJobs.for "ProcessRetrievedDataWorker-#{retrieved_data_id}" do
      retrieved_data = RetrievedData.find retrieved_data_id
      ProcessRetrievedData.new(retrieved_data).execute
    end
  end
end

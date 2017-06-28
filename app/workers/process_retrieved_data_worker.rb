class ProcessRetrievedDataWorker
  include Sidekiq::Worker
  sidekiq_options retry: false, unique: :until_and_while_executing

  def perform(retrieved_data_id)
    UniqueJobs.for "ProcessRetrievedDataWorker-#{retrieved_data_id}" do
      retrieved_data = RetrievedData.find retrieved_data_id
      ProcessRetrievedData.new(retrieved_data).execute if retrieved_data.not_processed?
    end
  end
end

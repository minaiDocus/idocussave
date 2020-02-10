class ProcessRetrievedDataWorker
  include Sidekiq::Worker
  sidekiq_options retry: false, unique: :until_and_while_executing

  def perform
    RetrievedData.not_processed.each do |retrieved_data|
      UniqueJobs.for "ProcessRetrievedData-#{retrieved_data.id}" do
        ProcessRetrievedData.delay.process(retrieved_data.id)
      end
    end
  end

end
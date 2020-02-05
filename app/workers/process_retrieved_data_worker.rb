class ProcessRetrievedDataWorker
  include Sidekiq::Worker
  sidekiq_options retry: false, unique: :until_and_while_executing

  def perform
    UniqueJobs.for 'ProcessRetrievedDataWorker', 1.day do
      RetrievedData.not_processed.each do |retrieved_data|
        UniqueJobs.for "ProcessRetrievedData-#{retrieved_data.id}" do
          ProcessRetrievedData.new(retrieved_data).execute
        end
      end
    end
  end

end
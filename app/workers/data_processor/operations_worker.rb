class DataProcessor::OperationsWorker
  include Sidekiq::Worker
  sidekiq_options retry: false

  def perform
    UniqueJobs.for 'ProcessOperations', 2.days do
      DataProcessor::Operation.execute
    end
  end
end

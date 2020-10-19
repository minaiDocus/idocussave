class DataProcessor::McfWorker
  include Sidekiq::Worker
  sidekiq_options queue: :default, retry: false

  def perform
    UniqueJobs.for 'McfProcessor' do
      DataProcessor::Mcf.execute
    end
  end
end
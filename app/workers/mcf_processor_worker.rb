class McfProcessorWorker
  include Sidekiq::Worker
  sidekiq_options queue: :default, retry: false

  def perform
    UniqueJobs.for 'McfProcessor' do
      McfProcessor.execute
    end
  end
end
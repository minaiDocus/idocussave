class JobOrchestratorWorker
  include Sidekiq::Worker
  sidekiq_options queue: :high, retry: false

  def perform
    UniqueJobs.for 'JobOrchestrator' do
      JobsOrchestrator.perform
    end
  end
end

class JobOrchestratorWorker
  include Sidekiq::Worker
  sidekiq_options queue: :default, retry: :false, unique: :until_and_while_executing

  def perform
    JobsOrchestrator.perform
  end
end

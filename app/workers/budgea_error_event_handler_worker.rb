class BudgeaErrorEventHandlerWorker
  include Sidekiq::Worker
  sidekiq_options queue: :low, retry: false

  def perform
    UniqueJobs.for 'BudgeaErrorEventHandlerWorker' do
      BudgeaErrorEventHandlerService.execute
    end
  end
end
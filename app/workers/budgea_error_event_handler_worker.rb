class BudgeaErrorEventHandlerWorker
  include Sidekiq::Worker
  sidekiq_options queue: :low, retry: false

  def perform
    UniqueJobs.for 'BudgeaErrorEventHandlerWorker' do
      BudgeaErrorEventHandlerService.new.execute
    end
  end
end
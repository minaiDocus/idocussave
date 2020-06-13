class BudgeaErrorEventHandlerWorker
  include Sidekiq::Worker
  sidekiq_options queue: :low, retry: false

  def perform
    UniqueJobs.for 'BudgeaErrorEventHandlerWorker' do
      BudgeaErrorEventHandlerService.new.execute(Retriever.need_refresh.first(10))
    end
  end
end
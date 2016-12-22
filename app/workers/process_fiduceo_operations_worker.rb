class ProcessFiduceoOperationsWorker
  include Sidekiq::Worker
  sidekiq_options queue: :process_fiduceo_operations, retry: :false, unique: :until_and_while_executing

  def perform
    OperationService.process
  end
end

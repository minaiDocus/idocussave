class RetrieveOcrProcessedDocumentWorker
  include Sidekiq::Worker
  sidekiq_options queue: :high, retry: false

  def perform
    UniqueJobs.for 'RetrieveOcrProcessedDocument' do
      AccountingWorkflow::OcrProcessing.fetch
    end
  end
end

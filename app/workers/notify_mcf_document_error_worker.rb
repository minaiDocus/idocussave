class NotifyMcfDocumentErrorWorker
  include Sidekiq::Worker
  sidekiq_options queue: :default, retry: false

  def perform()
    UniqueJobs.for "NotifyMcfDocumentError" do
      NotifyMcfDocumentError.execute()
    end
  end
end

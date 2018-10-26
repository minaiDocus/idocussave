class NotifyPreAssignmentExportWorker
  include Sidekiq::Worker
  sidekiq_options queue: :default, retry: false

  def perform()
    UniqueJobs.for "NotifyPreAssignmentExport" do
      NotifyPreAssignmentExport.execute()
    end
  end
end

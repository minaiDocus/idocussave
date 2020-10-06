class Notifications::PreAssignmentExportWorker
  include Sidekiq::Worker
  sidekiq_options queue: :default, retry: false

  def perform()
    UniqueJobs.for "NotifyPreAssignmentExport" do
      Notifications::PreAssignments.new.notify_pre_assignment_export
    end
  end
end
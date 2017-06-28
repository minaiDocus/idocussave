class GroupDocumentWorker
  include Sidekiq::Worker
  sidekiq_options retry: false, unique: :until_and_while_executing

  def perform(file_path)
    UniqueJobs.for "GroupDocument-#{file_path}", 1.day, 2 do
      AccountingWorkflow::GroupDocument.new(file_path).execute if File.exist?(file_path)
    end
  end
end

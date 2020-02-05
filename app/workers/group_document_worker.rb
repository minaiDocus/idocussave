class GroupDocumentWorker
  include Sidekiq::Worker
  sidekiq_options retry: false, unique: :until_and_while_executing

  def perform
    UniqueJobs.for "GroupDocumentWorker", 1.day do
      Dir.glob(AccountingWorkflow.grouping_dir.join('output/*.xml')).select do |file_path|
        File.atime(file_path) < 1.minute.ago
      end.map do |file_path|
        UniqueJobs.for "GroupDocument-#{file_path}", 1.day, 2 do
          AccountingWorkflow::GroupDocument.new(file_path).execute if File.exist?(file_path)
        end
      end
    end
  end
end
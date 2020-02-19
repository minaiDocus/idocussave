class GroupDocumentWorker
  include Sidekiq::Worker
  sidekiq_options retry: false, unique: :until_and_while_executing

  def perform
    Dir.glob(AccountingWorkflow.grouping_dir.join('output/*.xml')).select do |file_path|
      File.exist?(file_path.to_s) && File.atime(file_path) < 1.minute.ago
    end.map do |file_path|
      UniqueJobs.for "GroupDocument-#{file_path}", 1.day, 2 do
        AccountingWorkflow::GroupDocument.delay.process(file_path)
      end
    end
  end
end
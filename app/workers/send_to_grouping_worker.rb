class SendToGroupingWorker
  include Sidekiq::Worker
  sidekiq_options retry: false, unique: :until_and_while_executing

  def perform
    UniqueJobs.for "SendToGroupingWorker", 1.day do
      TempPack.bundle_processable.each do |temp_pack|
        temp_pack.temp_documents.bundle_needed.by_position.each do |temp_document|
          UniqueJobs.for "SendToGrouping-#{temp_document.id}" do
            AccountingWorkflow::SendToGrouping.new(temp_document).execute
          end
        end
      end
    end
  end
end
class SendToGroupingWorker
  include Sidekiq::Worker
  sidekiq_options retry: false, unique: :until_and_while_executing

  def perform
    TempPack.bundle_processable.each do |temp_pack|
      temp_pack.temp_documents.bundle_needed.by_position.each do |temp_document|
        AccountingWorkflow::SendToGrouping.delay.process(temp_document.id)
      end
    end
  end
end
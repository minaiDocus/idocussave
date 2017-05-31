class PublishDocumentWorker
  include Sidekiq::Worker
  sidekiq_options retry: false, unique: :until_and_while_executing

  def perform(temp_pack_id)
    UniqueJobs.for "PublishDocument-#{temp_pack_id}", 1.day, 2 do
      temp_pack = TempPack.find(temp_pack_id)
      AccountingWorkflow::TempPackProcessor.process(temp_pack) if temp_pack.not_processed?
    end
  end
end

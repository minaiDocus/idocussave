class PublishDocumentWorker
  include Sidekiq::Worker
  sidekiq_options retry: false, unique: :until_and_while_executing

  def perform
    TempPack.not_processed.each do |temp_pack|
      UniqueJobs.for "PublishDocument-#{temp_pack.id}", 2.hours, 2 do
        AccountingWorkflow::TempPackProcessor.delay.process(temp_pack.id)
      end
    end
  end

end
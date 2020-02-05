class PublishDocumentWorker
  include Sidekiq::Worker
  sidekiq_options retry: false, unique: :until_and_while_executing

  def perform
    UniqueJobs.for 'PublishDocumentWorker', 1.day do
      TempPack.not_processed.each do |temp_pack|
        UniqueJobs.for "PublishDocument-#{temp_pack.id}", 2.hours, 2 do
          AccountingWorkflow::TempPackProcessor.process(temp_pack)
        end
      end
    end
  end

end
class RetrieveEmailedDocumentWorker
  include Sidekiq::Worker
  sidekiq_options retry: false, unique: :until_and_while_executing

  def perform
    if EmailedDocument.config.is_enabled
      UniqueJobs.for 'RetrieveEmailedDocument' do
        EmailedDocument.fetch_all
      end
    end
  end
end

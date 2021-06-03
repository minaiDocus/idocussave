class Archive::ResendDocumentCorruptedWorker
  include Sidekiq::Worker
  sidekiq_options retry: false, unique: :until_and_while_executing

  def perform
    UniqueJobs.for "ResendDocumentCorrupted", 1.hours do
      Archive::ResendDocumentCorruptedService.execute
    end
  end
end
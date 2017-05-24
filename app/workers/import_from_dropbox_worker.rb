class ImportFromDropboxWorker
  include Sidekiq::Worker
  sidekiq_options retry: :false

  def perform
    UniqueJobs.for('ImportFromDropbox', 6.hours) do
      DropboxImport.check
    end
  end
end

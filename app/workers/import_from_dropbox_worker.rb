class ImportFromDropboxWorker
  include Sidekiq::Worker
  sidekiq_options retry: false

  def perform
    UniqueJobs.for 'ImportFromDropbox' do
      DropboxImport.check
    end
  end
end

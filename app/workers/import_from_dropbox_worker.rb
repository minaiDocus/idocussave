class ImportFromDropboxWorker
  include Sidekiq::Worker
  sidekiq_options queue: :file_import, retry: false

  def perform
    UniqueJobs.for 'ImportFromDropbox' do
      DropboxImport.check
    end
  end
end

class FileImport::DropboxWorker
  include Sidekiq::Worker
  sidekiq_options queue: :file_import, retry: false

  def perform
    UniqueJobs.for 'ImportFromDropbox' do
      FileImport::Dropbox.check
    end
  end
end
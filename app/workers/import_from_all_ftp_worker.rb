class ImportFromAllFTPWorker
  include Sidekiq::Worker
  sidekiq_options queue: :file_import, retry: false

  def perform
    UniqueJobs.for 'ImportFromAllFTP' do
      FTPImport.execute
    end
  end
end

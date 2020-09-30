class FileImport::FtpFromAllWorker
  include Sidekiq::Worker
  sidekiq_options queue: :file_import, retry: false

  def perform
    UniqueJobs.for 'ImportFromAllFTP' do
      FileImport::Ftp.execute
    end
  end
end

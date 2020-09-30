class FileImport::FtpWorker
  include Sidekiq::Worker
  sidekiq_options queue: :file_import, retry: false

  def perform(ftp_id)
    UniqueJobs.for "ImportFromFTP-#{ftp_id}" do
      ftp = Ftp.find ftp_id
      FileImport::Ftp.new(ftp).execute
    end
  end
end

class ImportFromFTPWorker
  include Sidekiq::Worker
  sidekiq_options queue: :file_import, retry: false

  def perform(ftp_id)
    UniqueJobs.for "ImportFromFTP-#{ftp_id}" do
      ftp = Ftp.find ftp_id
      FTPImport.new(ftp).execute
    end
  end
end

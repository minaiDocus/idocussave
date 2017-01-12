class SyncRemoteFilesWorker
  include Sidekiq::Worker
  sidekiq_options queue: :sync_remote_files, retry: :false, unique: :until_and_while_executing


  def perform(*args)
    DropboxImport.check
  end
end

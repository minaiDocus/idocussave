class ImportFromAllFTPWorker
  include Sidekiq::Worker
  sidekiq_options retry: false

  def perform
    UniqueJobs.for 'ImportFromAllFTP' do
      FTPImport.execute
    end
  end
end

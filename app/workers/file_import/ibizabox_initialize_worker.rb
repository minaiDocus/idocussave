class FileImport::IbizaboxInitializeWorker
  include Sidekiq::Worker
  sidekiq_options queue: :file_import, retry: false

  def perform
    UniqueJobs.for 'InitializeIbizaboxImport' do
      FileImport::Ibizabox.init
    end
  end
end

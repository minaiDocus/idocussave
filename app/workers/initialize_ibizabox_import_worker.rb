class InitializeIbizaboxImportWorker
  include Sidekiq::Worker
  sidekiq_options queue: :file_import, retry: false

  def perform
    UniqueJobs.for 'InitializeIbizaboxImport' do
      IbizaboxImport.init
    end
  end
end

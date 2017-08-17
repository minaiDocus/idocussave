class InitializeIbizaboxImportWorker
  include Sidekiq::Worker
  sidekiq_options retry: false

  def perform
    UniqueJobs.for 'InitializeIbizaboxImport' do
      IbizaboxImport.init
    end
  end
end

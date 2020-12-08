class FileImport::IbizaboxWorker
  include Sidekiq::Worker
  sidekiq_options queue: :file_import, retry: false

  def perform
    UniqueJobs.for 'ImportFromIbizabox' do
      IbizaboxFolder.ready.each do |folder|
        user = folder.user
        next unless user && user.organization.ibiza.try(:first_configured?) && user.uses?(:ibiza) && user.still_active?

        FileImport::Ibizabox.execute(folder)
      end
    end
  end
end
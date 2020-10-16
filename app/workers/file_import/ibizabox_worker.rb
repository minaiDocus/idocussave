class FileImport::IbizaboxWorker
  include Sidekiq::Worker
  sidekiq_options queue: :file_import, retry: false

  def perform
    UniqueJobs.for 'ImportFromIbizabox' do
      IbizaboxFolder.ready.includes(:user).map(&:user).uniq.each do |user|
        next unless user.organization.ibiza.try(:first_configured?) && user.uses_ibiza? && user.still_active?

        user.ibizabox_folders.ready.each do |folder|
          FileImport::Ibizabox.execute(folder)
        end
      end
    end
  end
end
class FileImport::IbizaboxWorker
  include Sidekiq::Worker
  sidekiq_options queue: :file_import, retry: false

  def perform
    UniqueJobs.for 'ImportFromIbizabox' do
      IbizaboxFolder.ready_or_blocked_processing.not_recently_checked.order(last_checked_at: :asc).limit(10).each do |folder|
        user = folder.user
        folder.update_attribute(:last_checked_at, Time.now)

        next unless user && user.organization.ibiza.try(:first_configured?) && user.uses?(:ibiza) && user.still_active?

        FileImport::Ibizabox.execute(folder)
      end
    end
  end
end
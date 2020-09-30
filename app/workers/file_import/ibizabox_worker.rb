class FileImport::IbizaboxWorker
  include Sidekiq::Worker
  sidekiq_options queue: :file_import, retry: false

  def perform(user_id)
    user = User.find user_id
    UniqueJobs.for("ImportFromIbizabox-#{user.id}") do
      user.ibizabox_folders.ready.each do |folder|
        FileImport::Ibizabox.execute(folder)
      end
    end
  end
end
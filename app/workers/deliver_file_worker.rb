class DeliverFileWorker
  include Sidekiq::Worker
  sidekiq_options queue: :low, retry: :false

  def perform(service_prefix)
    UniqueJobs.for("DeliverFile_to_#{service_prefix}", 1.day) do
      DeliverFile.to(service_prefix)
    end
  end
end

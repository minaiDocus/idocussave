class RemindToOrderNewKitWorker
  include Sidekiq::Worker
  sidekiq_options queue: :default, retry: false

  def perform
    UniqueJobs.for 'RemindToOrderNewKitWorker' do
      RemindToOrderNewKit.execute
    end
  end
end

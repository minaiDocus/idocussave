class Order::RemindToNewKitWorker
  include Sidekiq::Worker
  sidekiq_options queue: :default, retry: false

  def perform
    UniqueJobs.for 'RemindToOrderNewKitWorker' do
      Order::RemindToNewKit.execute
    end
  end
end

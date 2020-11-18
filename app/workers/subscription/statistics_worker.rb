class Subscription::StatisticsWorker
  include Sidekiq::Worker
  sidekiq_options queue: :default, retry: false

  def perform
    UniqueJobs.for 'GenerateSubscriptionStatistics' do
      StatisticsManager::Subscription.generate_current_statistics
    end
  end
end

class RefreshDashboardStatisticsWorker
  include Sidekiq::Worker
  sidekiq_options retry: false

  def perform
    UniqueJobs.for 'RefreshDashboardStatistics' do
      StatisticsManager::Dashboard.generate_statistics
    end
  end
end

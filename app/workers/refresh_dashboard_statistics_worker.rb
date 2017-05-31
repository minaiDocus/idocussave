class RefreshDashboardStatisticsWorker
  include Sidekiq::Worker
  sidekiq_options retry: false

  def perform
    UniqueJobs.for 'RefreshDashboardStatistics' do
      StatisticsManager::Generator.generate_dashboard_statistics
    end
  end
end

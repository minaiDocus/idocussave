class RefreshDashboardStatisticsWorker
  include Sidekiq::Worker
  sidekiq_options queue: :default, retry: :false, unique: :until_and_while_executing

  def perform
    StatisticsManager::Generator.generate_dashboard_statistics
  end
end

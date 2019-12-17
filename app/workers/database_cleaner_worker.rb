class DatabaseCleanerWorker
  include Sidekiq::Worker

  def perform
      DatabaseCleanerService.clear_all
  end
end
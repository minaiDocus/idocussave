class DatabaseCleanerWorker
  include Sidekiq::Worker

  def perform
    UniqueJobs.for "DatabaseCleaner" do
      DatabaseCleanerService.new.clear_all
    end
  end
end
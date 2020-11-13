class System::DatabaseCleanerWorker
  include Sidekiq::Worker

  def perform
    UniqueJobs.for "DatabaseCleaner" do
      System::DatabaseCleaner.new.clear_all
    end
  end
end
class DataVerificatorWorker
  include Sidekiq::Worker

  def perform
    UniqueJobs.for "DataVerificator" do
      DataVerificator::DataVerificator.execute
    end
  end
end
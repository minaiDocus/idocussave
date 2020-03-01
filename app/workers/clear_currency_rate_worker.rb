class ClearCurrencyRateWorker
  include Sidekiq::Worker

  def perform
    UniqueJobs.for 'ClearCurrencyRate' do
      CurrencyRate.clear_all
    end
  end
end
class ClearCurrencyRateWorker
  include Sidekiq::Worker

  def perform
      CurrencyRate.clear_all
  end
end
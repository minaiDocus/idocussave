class Cedricom::ImportTransactionsWorker
  include Sidekiq::Worker
  sidekiq_options queue: :cedricom, retry: false

  def perform
    UniqueJobs.for 'ImportTransactions' do
      Cedricom::ImportTransactions.perform
    end
  end
end
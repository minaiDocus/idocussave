class Bridge::RefreshUserTransactionsWorker
  include Sidekiq::Worker
  sidekiq_options queue: :bridge

  def perform(user_id)
    UniqueJobs.for "RefreshUserTransactionsWorker-#{user_id}" do
      user = User.find(user_id)

      Bridge::GetTransactions.new(user).execute
    end
  end
end

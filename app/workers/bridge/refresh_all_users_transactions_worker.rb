class Bridge::RefreshAllUsersTransactionsWorker
  include Sidekiq::Worker
  sidekiq_options queue: :bridge

  def perform
    UniqueJobs.for "RefreshAllUsersTransactionsWorker" do
      user_ids = BankAccount.bridge.configured.bridge.pluck(:user_id)

      user_ids.each { |user_id| Bridge::RefreshUserTransactionsWorker.perform_async(user_id) }
    end
  end
end

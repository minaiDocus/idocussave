class Bridge::RefreshUserAccountsWorker
  include Sidekiq::Worker
  sidekiq_options queue: :bridge

  def perform(user_id)
    UniqueJobs.for "RefreshUserAccountsWorker-#{user_id}" do
      user = User.find(user_id)

      Bridge::GetAccounts.new(user).execute
    end
  end
end

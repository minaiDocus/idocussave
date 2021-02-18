class Bridge::RefreshUserItemsWorker
  include Sidekiq::Worker
  sidekiq_options queue: :bridge

  def perform(user_id)
    UniqueJobs.for "RefreshUserItemsWorker-#{user_id}" do
      user = User.find(user_id)

      Bridge::GetItems.new(user).execute

      Bridge::RefreshUserAccountsWorker.perform_async(user_id)
    end
  end
end

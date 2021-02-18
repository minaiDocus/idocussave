class Bridge::RefreshAllUsersItemsWorker
  include Sidekiq::Worker
  sidekiq_options queue: :bridge

  def perform
    UniqueJobs.for "RefreshAllUsersItemsWorker" do
      user_ids = BridgeAccount.pluck(:user_id)

      user_ids.each { |user_id| Bridge::RefreshUserItemsWorker.perform_async(user_id) }
    end
  end
end

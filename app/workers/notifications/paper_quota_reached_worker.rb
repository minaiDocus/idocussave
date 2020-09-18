class Notifications::PaperQuotaReachedWorker
  include Sidekiq::Worker
  sidekiq_options queue: :default, retry: false

  def perform
    UniqueJobs.for 'NotificationsPaperQuotaReachedWorker' do
      Period.current.paper_quota_reached.paper_quota_reached_not_notified.each do |period|
        Notifications::PaperQuotas.new({period: period, user: period.user, organization: period.organization}).notify_paper_quota_reached
      end
    end
  end
end

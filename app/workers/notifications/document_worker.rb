class Notifications::DocumentWorker
  include Sidekiq::Worker
  sidekiq_options retry: false

  def perform
    UniqueJobs.for 'DocumentNotification' do
      start_at = 1.day.ago.localtime.beginning_of_day
      end_at   = start_at.end_of_day
      Notifications::Documents.new.notify_updated(start_at, end_at)

      Notifications::Documents.new.notify_pending
    end
  end
end
require 'spec_helper'
Sidekiq::Testing.inline! #execute jobs immediatly

describe Notifications::PaperQuotas do
  before(:each) do
    DatabaseCleaner.start
    Timecop.freeze(Time.local(2020,9,21))    

    @organization = FactoryBot.create :organization, code: 'IDOC'
    @user = FactoryBot.create :user, code: 'IDOC%001', organization: @organization
    @member = Member.create(user: @user, organization: @organization, role: 'admin', code: 'IDOC%LEADX')
    @organization.admin_members << @user.memberships.first
    @user.create_notify
    notify = @user.notify
    notify.paper_quota_reached = true
    notify.save

    @subscription = Subscription.create(user: @user, organization: @organization, period_duration: 1)
    @period = Period.create(subscription: @subscription, duration: 1, start_date: Date.parse("2020-09-01"), user: @user)
  end

  after(:each) do
    Timecop.return
    DatabaseCleaner.clean
  end

  context 'Paper quota reached notifications' do
    it 'Notify paper quota reached' do
      Notifications::PaperQuotas.new({period: @period, user: @period.user, organization: @period.organization}).notify_paper_quota_reached

      notification = Notification.last(2)

      notif_title = 'Quota de feuille atteint'
      message_1   = 'Votre quota de feuille mensuel est atteint.'
      message_2   = 'Le quota de feuille mensuel est atteint pour le client IDOC%001. Hors forfait de 0,12 cts HT par feuille et pièce comptable.'

      expect(notification.last.user).to eq @user
      expect(notification.last.notice_type).to eq 'paper_quota_reached'
      expect(notification.last.title).to match /#{notif_title}/
      expect(notification.first.title).to match /#{notif_title}/
      expect(notification.last.message).to eq message_2
      expect(notification.first.message).to eq message_1

      expect(@period.reload.is_paper_quota_reached_notified).to be true

      mails = ActionMailer::Base.deliveries.last(2)

      expect(mails[0].to).to eq [@user.email]
      expect(mails[0].subject).to eq "[iDocus] #{notif_title}"
      expect(mails[0].body.encoded).to include message_1
      expect(mails[1].subject).to eq "[iDocus] #{notif_title}"
      expect(mails[1].body.encoded).to include message_2
    end
  end
end
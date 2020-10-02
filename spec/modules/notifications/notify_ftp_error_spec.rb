require 'spec_helper'
Sidekiq::Testing.inline! #execute jobs immediatly

describe Notifications::Ftp do
  before(:each) do
    DatabaseCleaner.start
    Timecop.freeze(Time.local(2020,9,28))

    @organization = Organization.create(name: 'iDocus', code: 'IDOC')
    @ftp = Ftp.new(organization: @organization, host: 'ftp://localhost', is_configured: true)
    @user = FactoryBot.create(:user, code: 'IDOC%0001', organization: @organization)
    @user.options = UserOptions.create(user: @user, is_upload_authorized: true)
    @user.create_notify
    notify = @user.notify
    notify.ftp_auth_failure = true
    notify.save

    @message = "Votre identifiant et/ou mot de passe sont invalides, veuillez les reconfigurer"
  end

  after(:each) do
    Timecop.return
    DatabaseCleaner.clean
  end

  context 'FTPError Notifications' do
    it 'Notify ftp_auth_failure:notify_user_ftp_auth_failure' do
      Notifications::Ftp.new({users: [@user], notice_type: 'ftp_auth_failure', ftp: @ftp}).notify_ftp_auth_failure

      notification = Notification.last

      notif_title = 'Livraison FTP - Reconfiguration requise'

      expect(notification.user).to eq @user
      expect(notification.notice_type).to eq 'ftp_auth_failure'
      expect(notification.title).to eq notif_title
      expect(notification.message).to match /#{@message}/

      mail = ActionMailer::Base.deliveries.last

      expect(mail.to).to eq [@user.email]
      expect(mail.subject).to eq "[iDocus] #{notif_title}"
      expect(mail.body.encoded).to include @message
    end

    it 'Notify ftp_auth_failure:notify_organization_ftp_auth_failure' do
      Notifications::Ftp.new({users: [@user], notice_type: 'org_ftp_auth_failure', ftp: @ftp}).notify_ftp_auth_failure

      notification = Notification.last

      notif_title = 'Import/Export FTP - Reconfiguration requise'

      expect(notification.user).to eq @user
      expect(notification.notice_type).to eq 'org_ftp_auth_failure'
      expect(notification.title).to eq notif_title
      expect(notification.message).to match /#{@message}/

      mail = ActionMailer::Base.deliveries.last

      expect(mail.to).to eq [@user.email]
      expect(mail.subject).to eq "[iDocus] #{notif_title}"
      expect(mail.body.encoded).to include @message
    end
  end
end
require 'spec_helper'
Sidekiq::Testing.inline! #execute jobs immediatly

describe Notifications::Dropbox do
  before(:each) do
    DatabaseCleaner.start
    Timecop.freeze(Time.local(2020,9,21))

    @organization = FactoryBot.create :organization, code: 'IDOC'
    @user = FactoryBot.create :user, code: 'IDOC%001', organization: @organization
    @member = Member.create(user: @user, organization: @organization, role: 'admin', code: 'IDOC%LEADX')
    @organization.admin_members << @user.memberships.first
    @user.create_notify
    notify = @user.notify
    notify.pre_assignment_ignored_piece = true
    notify.save

    @user.external_file_storage = ExternalFileStorage.create(user_id: @user.id)

    @dropbox = @user.external_file_storage.dropbox_basic
    @dropbox.access_token = 'K4z7I_InsgsAAAAAAAAAkZ76RjGf_qZVQ6y72HOjmCJ1FWGFufHC9ZGbfuqO3fQO'
    @dropbox.save
    @dropbox.enable
  end

  after(:each) do
    Timecop.return
    DatabaseCleaner.clean
  end

  context 'Dropbox errors notifications' do
    it 'Notify dropbox_invalid_access_token' do
      Notifications::Dropbox.new({user: @dropbox.user}).notify_dropbox_invalid_access_token

      notification = Notification.last

      notif_title  = 'Dropbox - Reconfiguration requise'
      notif_message = "Votre accès à Dropbox a été révoqué, veuillez le reconfigurer"

      expect(notification.user).to eq @user
      expect(notification.notice_type).to eq 'dropbox_invalid_access_token'
      expect(notification.title).to eq notif_title
      expect(notification.message).to match /#{notif_message}/

      mail = ActionMailer::Base.deliveries.last

      expect(mail.to).to eq [@user.email]
      expect(mail.subject).to eq "[iDocus] #{notif_title}"
      expect(mail.body.encoded).to include notif_message
    end

    it 'Notify dropbox_insufficient_space' do
      Notifications::Dropbox.new({user: @dropbox.user}).notify_dropbox_insufficient_space

      notification = Notification.last

      notif_title = 'Dropbox - Espace insuffisant'

      expect(notification.user).to eq @user
      expect(notification.notice_type).to eq 'dropbox_insufficient_space'
      expect(notification.title).to eq notif_title
      expect(notification.message).to match /Votre compte Dropbox n'a plus d'espace, la livraison automatique a donc été désactivé, veuillez libérer plus d'espace avant de la réactiver./

      mail = ActionMailer::Base.deliveries.last

      expect(mail.to).to eq [@user.email]
      expect(mail.subject).to eq "[iDocus] #{notif_title}"
      expect(mail.body.encoded).to include "Votre compte Dropbox n&#39;a plus d&#39;espace, la livraison automatique a donc été désactivé, veuillez libérer plus d&#39;espace avant de la réactiver."
    end
  end
end
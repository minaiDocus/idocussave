require 'spec_helper'
Sidekiq::Testing.inline! #execute jobs immediatly

describe Notifications::McfDocuments do
  before(:each) do
    DatabaseCleaner.start
    Timecop.freeze(Time.local(2020,9,21))

    @organization = FactoryBot.create :organization, code: 'IDOC'
    @user = FactoryBot.create :user, code: 'IDOC%001', organization: @organization, mcf_storage: 'John Doe'
    @member = Member.create(user: @user, organization: @organization, role: 'admin', code: 'IDOC%LEADX')
    @organization.admin_members << @user.memberships.first
    @user.create_notify
    notify = @user.notify
    notify.mcf_document_errors = true
    notify.save

    mcf_document = { code: 'IDOC%001', journal: 'AC', original_file_name: 'test.pdf', access_token: '1234', user_id: @user.id, state: 'not_processable', is_notified: false }

    McfDocument.create(mcf_document)
  end

  after(:each) do
    Timecop.return
    DatabaseCleaner.clean
  end

  context 'MCF document errors notifications' do
    it 'Notify mcf_invalid_access_token' do
      Notifications::McfDocuments.new({users: @user.organization.admins}).notify_mcf_invalid_access_token

      notification = Notification.last

      notif_title   = 'My Company Files - Reconfiguration requise'
      notif_message =  'Votre accès à My Company Files a été révoqué, veuillez le reconfigurer'

      expect(notification.user).to eq @user
      expect(notification.notice_type).to eq 'mcf_invalid_access_token'
      expect(notification.title).to eq notif_title
      expect(notification.message).to match /#{notif_message}/

      mail = ActionMailer::Base.deliveries.last

      expect(mail.to).to eq [@user.email]
      expect(mail.subject).to eq "[iDocus] #{notif_title}"
      expect(mail.body.encoded).to include notif_message
    end

    it 'Notify mcf_insufficient_space' do
      Notifications::McfDocuments.new({users: @user.organization.admins}).notify_mcf_insufficient_space

      notification = Notification.last

      notif_title   = 'My Company Files - Espace insuffisant'
      notif_message =  'Votre accès à My Company Files a été révoqué, veuillez le reconfigurer'

      expect(notification.user).to eq @user
      expect(notification.notice_type).to eq 'mcf_insufficient_space'
      expect(notification.title).to eq 'My Company Files - Espace insuffisant'
      expect(notification.message).to eq "Votre compte My Company Files n'a plus d'espace, la livraison automatique a donc été désactivé, veuillez libérer plus d'espace avant de la réactiver."

      mail = ActionMailer::Base.deliveries.last

      expect(mail.to).to eq [@user.email]
      expect(mail.subject).to eq "[iDocus] #{notif_title}"
      expect(mail.body.encoded).to include "Votre compte My Company Files n&#39;a plus d&#39;espace, la livraison automatique a donc été désactivé, veuillez libérer plus d&#39;espace avant de la réactiver." 
    end
  end
end
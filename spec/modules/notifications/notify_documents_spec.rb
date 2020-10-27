require 'spec_helper'
Sidekiq::Testing.inline! #execute jobs immediatly

describe Notifications::Documents do
  before(:each) do
    DatabaseCleaner.start
    Timecop.freeze(Time.local(2020,9,21))

    @organization = FactoryBot.create :organization, code: 'IDOC'
    @user = FactoryBot.create :user, code: 'IDOC%001', organization: @organization
    @member = Member.create(user: @user, organization: @organization, role: 'admin', code: 'IDOC%LEADX')
    @organization.admin_members << @user.memberships.first

    @journal = @user.account_book_types.create(name: 'AC', description: 'TEST')
    @journal.save

    @user.create_notify

    @temp_pack = TempPack.find_or_create_by_name "#{@user.code} AC #{Time.now.strftime('%Y%m')} all"
    @temp_pack.user = @user
    @temp_pack.save

    @temp_document = TempDocument.new
    @temp_document.user                = @user
    @temp_document.organization        = @organization
    @temp_document.position            = 1
    @temp_document.temp_pack           = @temp_pack
    @temp_document.original_file_name  = '2pages.pdf'
    @temp_document.delivered_by        = 'IDOC%001'
    @temp_document.delivery_type       = 'upload'
    file_path = File.join(Rails.root, 'spec/support/files/2pages.pdf')
    @temp_document.cloud_content.attach(io: File.open(file_path), filename: File.basename(file_path)) if @temp_document.save
  end

  after(:each) do
    Timecop.return
    DatabaseCleaner.clean
  end

  context 'Document being processed notification' do
    before(:each) do
      notify = @user.notify
      notify.document_being_processed = true
      notify.save

      @notice_type   = 'document_being_processed'
      @notif_title   = 'Traitement de document'
      @notif_content = '1 nouveau document a été reçu et est en cours de traitement pour le lot suivant'
    end

    it 'Notify if ocr needed' do
      allow(Settings).to receive_message_chain('first.notify_errors_to').and_return('no')
      allow(DocumentTools).to receive(:need_ocr).with(any_args).and_return(true)

      @temp_document.ocr_needed

      temp_document_params = { temp_document: @temp_document, sender: User.find_by_code(@temp_document.delivered_by), user: @temp_document.user }

      Notifications::Documents.new(temp_document_params).notify_document_being_processed

      notification = Notification.last

      expect(notification.user).to eq @user
      expect(notification.notice_type).to eq @notice_type
      expect(notification.title).to match /#{@notif_title}/
      expect(notification.message).to match /#{@notif_content}/

      mail = ActionMailer::Base.deliveries.last

      expect(mail.to).to eq [@user.email]
      expect(mail.subject).to eq "[iDocus] Traitement de document"
      expect(mail.body.encoded).to include @notif_content
    end

    it 'Notify if is bundle needed' do
      allow(Settings).to receive_message_chain('first.notify_errors_to').and_return('no')

      allow(DocumentTools).to receive(:is_bundle_needed).with(any_args).and_return(true)

      @temp_document.bundle_needed

      temp_document_params = {temp_document: @temp_document, sender: User.find_by_code(@temp_document.delivered_by), user: @temp_document.user}

      Notifications::Documents.new(temp_document_params).notify_document_being_processed

      notification = Notification.last

      expect(notification.user).to eq @user
      expect(notification.notice_type).to eq @notice_type
      expect(notification.title).to match /#{@notif_title}/
      expect(notification.message).to match /#{@notif_content}/

      mail = ActionMailer::Base.deliveries.last

      expect(mail.to).to eq [@user.email]
      expect(mail.subject).to eq "[iDocus] Traitement de document"
      expect(mail.body.encoded).to include @notif_content
    end
  end

  context 'New scanned and published documents notifications' do
    it 'Notify new scanned document' do
      notify = @user.notify
      notify.new_scanned_documents = true
      notify.save

      subscription = Subscription.create(user: @user, organization: @organization, period_duration: 1)
      Billing::UpdatePeriod.new(subscription.current_period).execute
      Billing::Period.new user: @user, current_time: Time.local(2020,9,21)
      Period.create(subscription: subscription, duration: 1, start_date: Date.parse("2020-09-01"), user: @user)

      Notifications::Documents.new({ user: @user, new_count: [@temp_document].count }).notify_new_scaned_documents

      notification = Notification.last

      expect(notification.user).to eq @user
      expect(notification.notice_type).to eq 'new_scanned_documents'
      expect(notification.title).to match /Nouveau document papier reçu/
      expect(notification.message).to match /Le total des documents papier envoyés/
    end

    it 'Notify published document' do
      notify = @user.notify
      notify.published_docs = 'now'
      notify.save

      notif_title   = 'Nouveau document disponible'
      notif_message = '1 nouveau document a été ajouté dans'

      Notifications::Documents.new({ user: @user, temp_document: @temp_document, send_mail: true }).notify_published_document

      notification = Notification.last

      expect(notification.user).to eq @user
      expect(notification.notice_type).to eq 'published_document'
      expect(notification.title).to match /#{notif_title}/
      expect(notification.message).to match /#{notif_message}/

      mail = ActionMailer::Base.deliveries.last

      expect(mail.to).to eq [@user.email]
      expect(mail.subject).to eq "[iDocus] #{notif_title}"
      expect(mail.body.encoded).to include notif_message
    end
  end
end
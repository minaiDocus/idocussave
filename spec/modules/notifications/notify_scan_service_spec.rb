require 'spec_helper'
Sidekiq::Testing.inline! #execute jobs immediatly

describe Notifications::ScanService do
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

    @period = Period.create(duration: 1, start_date: Date.parse("2020-09-01"), user: @user, organization: @organization)

    temp_pack = TempPack.find_or_create_by_name "#{@user.code} AC #{Time.now.strftime('%Y%m')} all"
    temp_pack.user = @user
    temp_pack.save

    temp_document = TempDocument.new
    temp_document.user                = @user
    temp_document.organization        = @organization
    temp_document.position            = 1
    temp_document.temp_pack           = temp_pack
    temp_document.original_file_name  = '2pages.pdf'
    temp_document.delivered_by        = 'IDOC%001'
    temp_document.delivery_type       = 'upload'
    file_path = File.join(Rails.root, 'spec/support/files/2pages.pdf')
    temp_document.cloud_content.attach(io: File.open(file_path), filename: File.basename(file_path)) if temp_document.save
  end

  after(:each) do
    Timecop.return
    DatabaseCleaner.clean
  end

  context 'Scan service notifications' do
    it 'notify 1 document scanned but not delivered' do
      emails = Settings.create(notify_scans_not_delivered_to: ['jean@idocus.com'])

      document = PeriodDocument.new

      document.name         = 'IDOC%001 AC 202009 all'
      document.period       = @period
      document.user         = @user
      document.organization = @organization
      document.scanned_at   = Time.now
      document.save

      Notifications::ScanService.new.notify_not_delivered

      mail = ActionMailer::Base.deliveries.last

      expect(mail.to).to eq ["jean@idocus.com"]
      expect(mail.subject).to eq "[iDocus] 1 document(s) scanné(s) mais non livré(s)"
      expect(mail.body.encoded).to include "1 document(s) scanné(s) mais non livré(s) :"
    end

    it 'Send mail for uncomplete scan delivery' do
      emails = Settings.create(notify_scans_not_delivered_to: ['jean@idocus.com'])

      report = FactoryBot.create :report, user: @user, organization: @organization, name: 'IDOC%001 AC 20209'
      pack   = FactoryBot.create :pack, owner: @user, organization: @organization , name: (report.name + ' all')
      piece  = FactoryBot.create :piece, pack: pack, user: @user, organization: @organization, name: (report.name + ' 001')
      
      preseizure = FactoryBot.create :preseizure, user: @user, organization: @organization, report_id: report.id, piece: piece
        
      delivery = PreAssignmentDelivery.new
      delivery.report       = report
      delivery.deliver_to   = 'ibiza'
      delivery.user         = @user
      delivery.organization = @organization
      delivery.pack_name    = report.name
      delivery.software_id  = report.user.ibiza_id
      delivery.is_auto      = true
      delivery.grouped_date = Time.now
      delivery.total_item   = [preseizure].size
      delivery.preseizures  = [preseizure]
      delivery.error_message = 'force sending'

      delivery.save

      Notifications::ScanService.new({deliveries: [delivery]}).notify_uncompleted_delivery

      mail = ActionMailer::Base.deliveries.last

      expect(mail.to).to eq ["jean@idocus.com"]
      expect(mail.subject).to eq "[iDocus] 1 livraison(s) incomplète(s)"
      expect(mail.body.encoded).to include "1 livraison(s) incomplète(s) :"
    end
  end
end
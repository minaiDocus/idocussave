require 'spec_helper'
Sidekiq::Testing.inline! #execute jobs immediatly

describe Notifications::PreAssignments do
  before(:each) do
    DatabaseCleaner.start
    Timecop.freeze(Time.local(2020,9,28)) 

    @organization = FactoryBot.create :organization, code: 'IDOC'
    @user = FactoryBot.create :user, code: 'IDOC%001', organization: @organization
    @member = Member.create(user: @user, organization: @organization, role: 'admin', code: 'IDOC%LEADX')
    @organization.admin_members << @user.memberships.first
    @user.create_notify
    notify = @user.notify
    notify.detected_preseizure_duplication = true
    notify.save
  end

  after(:each) do
    Timecop.return
    DatabaseCleaner.clean
  end

  context 'PreAssignment notifications' do
    before(:each) do
      @preseizure = Pack::Report::Preseizure.new
      @preseizure.user          = @user
      @preseizure.organization  = @organization
      @preseizure.cached_amount = 10.0
      @preseizure.third_party   = 'Google'
      @preseizure.piece_number  = 'G001'
      @preseizure.date          = Time.local(2020, 9, 28)
      @preseizure.save

      journal = AccountBookType.create(name: 'AC', description: 'Achats')
      @user.account_book_types << journal
      @report              = Pack::Report.new
      @report.name         = "#{@user.code} AC #{Time.now.strftime('%Y%m')} all"
      @report.user         = @user
      @report.organization = @organization
      @report.save

      @report.preseizures << @preseizure

      pack   = FactoryBot.create :pack, owner: @user, organization: @organization , name: (@report.name + ' all')
      @piece  = FactoryBot.create :piece, pack: pack, user: @user, organization: @organization, name: (@report.name + ' 001')
    end

    it 'Notify duplicated preseizure' do
      preseizure = Pack::Report::Preseizure.new
      preseizure.user          = @user
      preseizure.organization  = @organization
      preseizure.cached_amount = 10.0
      preseizure.third_party   = 'Google'
      preseizure.piece_number  = 'G001'
      preseizure.date          = Time.local(2020, 9, 28)
      preseizure.save

      Notifications::PreAssignments.new({preseizure: preseizure}).notify_detected_preseizure_duplication

      notification = Notification.last

      notif_title  = 'Pré-affectation bloqué'

      expect(notification.user).to eq @user
      expect(notification.notice_type).to eq 'detected_preseizure_duplication'
      expect(notification.title).to match /#{notif_title}/
      expect(notification.message).to match /pré-affectation est susceptible d'être un doublon et a été bloqué/

      mail = ActionMailer::Base.deliveries.last

      expect(mail.to).to eq [@user.email]
      expect(mail.subject).to eq "[iDocus] #{notif_title}"
      expect(mail.body.encoded).to include "1 pré-affectation est susceptible d&#39;être un doublon et a été bloqué."
    end

    it 'Notify a pre assignment delivery failure with ibiza softwares' do
      notify = @user.notify
      notify.pre_assignment_delivery_errors = 'now'
      notify.save

      @preseizure.report_id = @report.id
      @preseizure.piece = @piece
      @preseizure.save
        
      delivery = PreAssignmentDelivery.new
      delivery.report       = @report
      delivery.deliver_to   = 'ibiza'
      delivery.user         = @user
      delivery.organization = @organization
      delivery.pack_name    = @report.name
      delivery.software_id  = @report.user.ibiza_id
      delivery.is_auto      = true
      delivery.grouped_date = Time.now
      delivery.total_item   = [@preseizure].size
      delivery.preseizures  = [@preseizure]
      delivery.error_message = 'force sending'

      delivery.save

      Notifications::PreAssignments.new({delivery: delivery, user: delivery.user}).notify_pre_assignment_delivery_failure

      notification = Notification.last

      notif_title  = 'Livraison de pré-affectation échouée'

      expect(notification.user).to eq @user
      expect(notification.notice_type).to eq 'pre_assignment_delivery_failure'
      expect(notification.title).to eq notif_title
      expect(notification.message).to eq "La pré-affectation suivante n'a pas pu être livrée : IDOC%001 AC 202009 all"
    end

    it 'Notify a new preassignment available' do
      notify = @user.notify
      notify.new_pre_assignment_available = true
      notify.save

      Notifications::PreAssignments.new({pre_assignment: @preseizure}).notify_new_pre_assignment_available

      notification = Notification.last

      notif_title   = 'Nouvelle pré-affectation disponible'
      notif_message =  '1 nouvelle pré-affectation est disponible pour le lot suivant'

      expect(notification.user).to eq @user
      expect(notification.notice_type).to eq 'new_pre_assignment_available'
      expect(notification.title).to match /#{notif_title}/
      expect(notification.message).to match /#{notif_message}/

      mail = ActionMailer::Base.deliveries.last

      expect(mail.to).to eq [@user.email]
      expect(mail.subject).to eq "[iDocus] #{notif_title}"
      expect(mail.body.encoded).to include notif_message
    end

    it 'Notify a preassignment export' do
      notify = @user.notify
      notify.pre_assignment_export = true
      notify.save

      export                = PreAssignmentExport.new
      export.report         = @report
      export.for            = 'ibiza'
      export.user           = @report.user
      export.organization   = @report.organization
      export.pack_name      = @report.name
      export.total_item     = [@preseizure].size
      export.preseizures    = [@preseizure]
      export.is_notified    = false
      export.state          = 'generated'
      export.save

      Notifications::PreAssignments.new.notify_pre_assignment_export

      notification = Notification.last

      notif_title  = 'Export d\'écritures comptables disponibles'

      expect(notification.user).to eq @user
      expect(notification.notice_type).to eq 'pre_assignment_export'
      expect(notification.title).to eq notif_title
      expect(notification.message).to match /- 1 export d'écritures comptables est disponible pour le dossier : IDOC%001/

      mail = ActionMailer::Base.deliveries.last

      expect(mail.to).to eq [@user.email]
      expect(mail.subject).to eq "[iDocus] #{notif_title}"
      expect(mail.body.encoded).to include "1 export d&#39;écritures comptables est disponible pour le dossier : IDOC%001"
    end

    it 'Notify a preassignment ignored piece' do
      notify = @user.notify
      notify.pre_assignment_ignored_piece = true
      notify.save

      @piece.origin               = 'scan'
      @piece.pre_assignment_state = 'ignored'
      @piece.save
      
      Notifications::PreAssignments.new({piece: @piece}).notify_pre_assignment_ignored_piece

      notification = Notification.last

      notif_title   = 'Pièce ignorée à la pré-affectation'
      notif_message = '1 pièce a été ignorée à la pré-affectation'

      expect(notification.user).to eq @user
      expect(notification.notice_type).to eq 'pre_assignment_ignored_piece'
      expect(notification.title).to eq notif_title
      expect(notification.message).to match /#{notif_message}/

      mail = ActionMailer::Base.deliveries.last

      expect(mail.to).to eq [@user.email]
      expect(mail.subject).to eq "[iDocus] #{notif_title}"
      expect(mail.body.encoded).to include notif_message
    end

    it 'unblocked 2 preseizures' do
      notify = @user.notify
      notify.detected_preseizure_duplication = true
      notify.save

      preseizure = Pack::Report::Preseizure.new
      preseizure.user          = @user
      preseizure.organization  = @organization
      preseizure.cached_amount = 11.0
      preseizure.third_party   = 'Google'
      preseizure.piece_number  = 'G002'
      preseizure.date          = Time.local(2020, 9, 28)
      preseizure.report        = @report
      preseizure.save

      preseizures = Pack::Report::Preseizure.all

      Notifications::PreAssignments.new({owner: @user, total: preseizures.size, unblocker: @unblocker}).notify_unblocked_preseizure

      notification = Notification.last

      notif_title   = 'Pré-affectations débloqués'
      notif_message = "2 pré-affectations ont été débloqués."

      expect(notification.user).to eq @user
      expect(notification.notice_type).to eq 'unblocked_preseizure'
      expect(notification.title).to match /#{notif_title}/
      expect(notification.message).to match /#{notif_message}/

      mail = ActionMailer::Base.deliveries.last

      expect(mail.to).to eq [@user.email]
      expect(mail.subject).to eq "[iDocus] #{notif_title}"
      expect(mail.body.encoded).to include notif_message
    end
  end
end
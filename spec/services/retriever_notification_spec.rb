require 'spec_helper'

RSpec.shared_examples "retriever's notifications for users" do |notify_params, deactivate_params, user_message, others_message|
  before(:all) do
    @notify_now = Proc.new { |r| RetrieverNotification.new(r).send(*notify_params) }
  end

  it 'notifies user' do
    @notify_now.call(@retriever)

    expect(Notification.count).to eq 1
    expect(@user.notifications.first.message).to eq user_message
  end

  describe 'given organization has a leader' do
    before(:all) do
      DatabaseCleaner.start

      @leader = create :prescriber, code: 'IDO%ADM', organization: @organization
      @leader.create_notify
      @organization.update(leader: @leader)
    end

    after(:all) do
      DatabaseCleaner.clean
    end

    describe 'given user has no group' do
      it 'notifies user and leader' do
        @notify_now.call(@retriever)

        expect(Notification.count).to eq 2
        expect(@user.notifications.first.message).to eq user_message
        expect(@leader.notifications.first.message).to eq others_message
      end

      if deactivate_params
        describe 'leader has deactivated notification' do
          before(:each) do
            @leader.notify.update_attribute(*deactivate_params)
          end

          it 'notifies user only' do
            @notify_now.call(@retriever)

            expect(Notification.count).to eq 1
            expect(@user.notifications.count).to eq 1
          end
        end
      end
    end

    describe 'given user is in the same group as collaborator and shared his account with contact' do
      before(:all) do
        DatabaseCleaner.start

        @collaborator = create :prescriber, code: 'IDO%COL1', organization: @organization
        @collaborator.create_notify
        group = Group.create(name: 'Customers', organization: @organization)
        group.members << @collaborator
        group.members << @user
        @contact = create :guest, code: 'IDO%SHR01', organization: @organization
        @contact.create_notify
        AccountSharing.create collaborator: @contact, account: @user, organization: @organization, is_approved: true
      end

      after(:all) do
        DatabaseCleaner.clean
      end

      it 'notifies 4 users' do
        @notify_now.call(@retriever)

        expect(Notification.count).to eq 4
        expect(@user.notifications.first.message).to eq user_message
        expect(@leader.notifications.first.message).to eq others_message
        expect(@collaborator.notifications.first.message).to eq others_message
        expect(@contact.notifications.first.message).to eq others_message
      end

      if deactivate_params
        describe "user has deactivated notification" do
          before(:each) do
            @user.notify.update_attribute(*deactivate_params)
          end

          it "notifies leader, collaborator and contact" do
            @notify_now.call(@retriever)

            expect(Notification.count).to eq 3
            expect(@leader.notifications.count).to eq 1
            expect(@collaborator.notifications.count).to eq 1
            expect(@contact.notifications.count).to eq 1
          end
        end

        describe "collaborator has deactivated notification" do
          before(:each) do
            @collaborator.notify.update_attribute(*deactivate_params)
          end

          it "notifies user, leader and contact" do
            @notify_now.call(@retriever)

            expect(Notification.count).to eq 3
            expect(@user.notifications.count).to eq 1
            expect(@leader.notifications.count).to eq 1
            expect(@contact.notifications.count).to eq 1
          end
        end

        describe "contact has deactivated notification" do
          before(:each) do
            @contact.notify.update_attribute(*deactivate_params)
          end

          it "notifies user, leader and collaborator" do
            @notify_now.call(@retriever)

            expect(Notification.count).to eq 3
            expect(@user.notifications.count).to eq 1
            expect(@leader.notifications.count).to eq 1
            expect(@collaborator.notifications.count).to eq 1
          end
        end
      end
    end
  end
end

describe RetrieverNotification do
  before(:all) do
    DatabaseCleaner.start

    @organization = create :organization, code: 'IDO'
    @user         = create :user, code: 'IDO%001', organization: @organization, first_name: 'John', last_name: 'Doe'
    @user.create_notify
    @journal      = create :account_book_type, user: @user
    @connector    = create :connector
    @retriever    = Retriever.new
    @retriever.user         = @user
    @retriever.budgea_id    = 7
    @retriever.connector    = @connector
    @retriever.name         = 'Connecteur de test'
    @retriever.journal      = @journal
    @retriever.state        = 'ready'
    @retriever.budgea_state = 'successful'
    @retriever.save
  end

  after(:all) { DatabaseCleaner.clean }

  before(:each) do
    DatabaseCleaner.start
    @user.reload
    @user.notify.reload
  end

  after(:each) { DatabaseCleaner.clean }

  describe '#notify_wrong_pass' do
    include_examples "retriever's notifications for users", :notify_wrong_pass, nil,
      "Votre mot de passe pour l'automate \"Connecteur de test\" est invalide. Veuillez le reconfigurer s'il vous plaît.",
      "Le mot de passe pour l'automate \"Connecteur de test\", du dossier IDO%001 - TeSt - John DOE, est invalide. Veuillez le reconfigurer s'il vous plaît."
  end

  describe '#notify_info_needed' do
    include_examples "retriever's notifications for users", :notify_info_needed, nil,
      "Veuillez fournir les informations demandées pour pouvoir continuer le processus de récupération de votre automate \"Connecteur de test\".",
      "Veuillez fournir les informations demandées pour pouvoir continuer le processus de récupération de l'automate \"Connecteur de test\" pour le dossier IDO%001 - TeSt - John DOE."
  end

  describe '#notify_website_unavailable' do
    include_examples "retriever's notifications for users", :notify_website_unavailable, [:r_site_unavailable, false],
      "Le site web du fournisseur/banque de votre automate \"Connecteur de test\" est actuellement indisponible.",
      "Le site web du fournisseur/banque de l'automate \"Connecteur de test\", du dossier IDO%001 - TeSt - John DOE, est actuellement indisponible."
  end

  describe '#notify_bug' do
    include_examples "retriever's notifications for users", :notify_bug, [:r_bug, false],
      "Votre automate \"Connecteur de test\" ne fonctionne pas correctement.",
      "L'automate \"Connecteur de test\" du dossier IDO%001 - TeSt - John DOE ne fonctionne pas correctement."
  end

  describe '#notify_new_documents' do
    include_examples "retriever's notifications for users", [:notify_new_documents, 15], [:r_new_documents, 'none'],
      "15 nouveaux documents ont été récupérés par votre automate \"Connecteur de test\".",
      "15 nouveaux documents ont été récupérés par l'automate \"Connecteur de test\" du dossier IDO%001 - TeSt - John DOE."

    describe 'given user has opted for delayed notification' do
      before(:all) do
        @user.notify.update(r_new_documents: 'delay')
      end

      it 'does not notify but increase the total number to be notified' do
        RetrieverNotification.new(@retriever).notify_new_documents(12)

        @user.notify.reload
        expect(Notification.count).to eq 0
        expect(@user.notify.r_new_documents_count).to eq 12
      end
    end
  end

  describe '#notify_new_operations' do
    include_examples "retriever's notifications for users", [:notify_new_operations, 30], [:r_new_operations, 'none'],
      "30 nouvelles opérations ont été récupérés par votre automate \"Connecteur de test\".",
      "30 nouvelles opérations ont été récupérés par l'automate \"Connecteur de test\" du dossier IDO%001 - TeSt - John DOE."

    describe 'given user has opted for delayed notification' do
      before(:all) do
        @user.notify.update(r_new_operations: 'delay')
      end

      it 'does not notify but increase the total number to be notified' do
        RetrieverNotification.new(@retriever).notify_new_operations(79)

        @user.notify.reload
        expect(Notification.count).to eq 0
        expect(@user.notify.r_new_operations_count).to eq 79
      end
    end
  end

  describe '#notify_action_needed' do
    describe 'given organization has a leader, user is in the same group as collaborator and shared his account with contact' do
      before(:all) do
        DatabaseCleaner.start

        @leader = create :prescriber, code: 'IDO%ADM', organization: @organization
        @leader.create_notify
        @organization.update(leader: @leader)
        @collaborator = create :prescriber, code: 'IDO%COL1', organization: @organization
        @collaborator.create_notify
        group = Group.create(name: 'Customers', organization: @organization)
        group.members << @collaborator
        group.members << @user
        @contact = create :guest, code: 'IDO%SHR01', organization: @organization
        @contact.create_notify
        AccountSharing.create collaborator: @contact, account: @user, organization: @organization, is_approved: true
      end

      after(:all) { DatabaseCleaner.clean }

      it 'notifies only user' do
        RetrieverNotification.new(@retriever).notify_action_needed

        expect(Notification.count).to eq 1
        expect(@user.notifications.first.message).to eq "Votre fournisseur/banque requiert que vous validiez leurs CGU sur leur site avant de pouvoir poursuivre le processus de récupération de votre automate \"Connecteur de test\"."
      end

      describe 'given user has deactivated notification' do
        before(:all) do
          @user.notify.update(r_action_needed: false)
        end

        it 'does not notify' do
          RetrieverNotification.new(@retriever).notify_action_needed

          expect(Notification.count).to eq 0
        end
      end
    end
  end

  describe '.notify_summary_updates' do
    it 'notifies delayed notifications' do
      user2 = create :user, code: 'IDO%002', organization: @organization, first_name: 'Jack', last_name: 'Spade'
      user2.create_notify

      @user.notify.update r_new_documents_count: 7, r_new_operations_count: 53

      RetrieverNotification.notify_summary_updates

      @user.notify.reload
      expect(Notification.count).to eq 2
      expect(@user.notifications.first.title).to eq 'Automate - Nouveaux documents'
      expect(@user.notifications.last.title).to eq 'Automate - Nouvelles opérations'
      expect(@user.notify.r_new_documents_count).to eq 0
      expect(@user.notify.r_new_operations_count).to eq 0
    end
  end

  describe '.notify_no_bank_account_configured' do
    describe 'given user is in the same group as collaborator' do
      before(:all) do
        DatabaseCleaner.start

        @collaborator = create :prescriber, code: 'IDO%COL1', organization: @organization
        @collaborator.create_notify
        group = Group.create(name: 'Customers', organization: @organization)
        group.members << @collaborator
        group.members << @user
      end

      after(:all) { DatabaseCleaner.clean }

      describe 'given a bank account is not selected and another is configured' do
        before(:each) do
          bank_account = BankAccount.new
          bank_account.user      = @user
          bank_account.retriever = @retriever
          bank_account.api_id    = 5
          bank_account.bank_name = @retriever.service_name
          bank_account.name      = 'Compte courant'
          bank_account.number    = '0001'
          bank_account.save!

          bank_account = BankAccount.new
          bank_account.user              = @user
          bank_account.retriever         = @retriever
          bank_account.api_id            = 6
          bank_account.bank_name         = @retriever.service_name
          bank_account.name              = 'Compte courant'
          bank_account.number            = '0002'
          bank_account.is_used           = true
          bank_account.journal           = 'AC'
          bank_account.accounting_number = 123
          bank_account.temporary_account = 456
          bank_account.start_date        = Date.today
          bank_account.save!
        end

        it 'does not notify' do
          RetrieverNotification.notify_no_bank_account_configured

          expect(Notification.count).to eq 0
        end
      end

      describe 'given bank account is not configured' do
        before(:each) do
          bank_account = BankAccount.new
          bank_account.user      = @user
          bank_account.retriever = @retriever
          bank_account.api_id    = 5
          bank_account.bank_name = @retriever.service_name
          bank_account.name      = 'Compte courant'
          bank_account.number    = '0001'
          bank_account.is_used   = true
          bank_account.save!
        end

        it 'notifies' do
          RetrieverNotification.notify_no_bank_account_configured

          expect(Notification.count).to eq 1
          expect(@collaborator.notifications.first.title).to eq 'Automate - En attente de configuration'
        end
      end
    end
  end
end
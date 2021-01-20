# -*- encoding : UTF-8 -*-
require 'spec_helper'

describe UploadedDocument do
  before(:all) do
    Timecop.freeze(Time.local(2020,4,22))
  end

  after(:all) do
    Timecop.return
  end

  describe '.new' do
    before(:all) do
      @file = File.open("#{Rails.root}/spec/support/files/upload.pdf", "r")
    end

    after(:all) do
      @file.close
    end

    context 'when arguments are valid' do
      context 'when current period' do
        before(:all) do
          Timecop.freeze(Time.local(2020,4,22))
        end

        after(:all) do
          Timecop.return
        end

        context 'when periodicity is monthly' do
          before(:all) do
            DatabaseCleaner.start
            @user = FactoryBot.create(:user, code: 'TS0001')
            @user.account_book_types.create(name: 'TS', description: 'TEST')
            @uploaded_document = UploadedDocument.new(@file, 'upload.pdf', @user, 'TS', 0)
            @temp_document = @uploaded_document.temp_document
          end

          after(:all) do
            DatabaseCleaner.clean
          end

          it { expect(@uploaded_document).to be_valid }

          describe 'temp_document' do
            subject { @temp_document }

            it { is_expected.to be_valid }
            it { is_expected.to be_persisted }
            it { expect(subject.position).to           eq 1 }
            it { expect(subject.delivered_by).to       eq 'TS0001' }
            it { expect(subject.delivery_type).to      eq 'upload' }
            it { expect(subject.original_file_name).to eq 'upload.pdf' }
            it { expect(subject.content_file_name).to  eq 'TS0001_TS_201301.pdf' }
          end
        end

        context 'when periodicity is quarterly' do
          before(:all) do
            DatabaseCleaner.start
            @user = FactoryBot.create(:user, code: 'TS0001')
            @subscription = @user.find_or_create_subscription
            @subscription.update_attribute(:period_duration, 3)
            Billing::UpdatePeriod.new(@subscription.current_period).execute
            @user.account_book_types.create(name: 'TS', description: 'TEST')
            @uploaded_document = UploadedDocument.new(@file, 'upload.pdf', @user, 'TS', 0)
            @temp_document = @uploaded_document.temp_document
          end

          after(:all) do
            DatabaseCleaner.clean
          end

          it 'temp_pack.name should equal TS0001 TS 2013T1 all' do
            expect(@temp_document.temp_pack.name).to eq('TS0001 TS 2013T1 all')
          end

          it { expect(@uploaded_document).to be_valid }

          describe 'temp_document' do
            subject { @temp_document }

            it { is_expected.to be_valid }
            it { is_expected.to be_persisted }
            it { expect(subject.position).to           eq 1 }
            it { expect(subject.delivered_by).to       eq 'TS0001' }
            it { expect(subject.delivery_type).to      eq 'upload' }
            it { expect(subject.original_file_name).to eq 'upload.pdf' }
            it { expect(subject.content_file_name).to  eq 'TS0001_TS_2013T1.pdf' }
          end
        end

        context 'when periodicity is yearly' do
          before(:all) do
            DatabaseCleaner.start
            @user = FactoryBot.create(:user, code: 'TS0001')
            @subscription = @user.find_or_create_subscription
            @subscription.update_attribute(:period_duration, 12)
            Billing::UpdatePeriod.new(@subscription.current_period).execute
            @user.account_book_types.create(name: 'TS', description: 'TEST')
            @uploaded_document = UploadedDocument.new(@file, 'upload.pdf', @user, 'TS', 0)
            @temp_document = @uploaded_document.temp_document
          end

          after(:all) do
            DatabaseCleaner.clean
          end

          it 'temp_pack.name should equal TS0001 TS 2013 all' do
            expect(@temp_document.temp_pack.name).to eq('TS0001 TS 2013 all')
          end

          it { expect(@uploaded_document).to be_valid }

          describe 'temp_document' do
            subject { @temp_document }

            it { is_expected.to be_valid }
            it { is_expected.to be_persisted }
            it { expect(subject.position).to           eq 1 }
            it { expect(subject.delivered_by).to       eq 'TS0001' }
            it { expect(subject.delivery_type).to      eq 'upload' }
            it { expect(subject.original_file_name).to eq 'upload.pdf' }
            it { expect(subject.content_file_name).to  eq 'TS0001_TS_2013.pdf' }
          end
        end
      end

      context 'when previous period is accepted' do
        before(:all) do
          Timecop.freeze(Time.local(2013,1,10))
        end

        after(:all) do
          Timecop.return
        end

        context 'when periodicity is monthly' do
          before(:all) do
            DatabaseCleaner.start
            @user = FactoryBot.create(:user, code: 'TS0001')
            @user.account_book_types.create(name: 'TS', description: 'TEST')
            @uploaded_document = UploadedDocument.new(@file, 'upload.pdf', @user, 'TS', 1)
            @temp_document = @uploaded_document.temp_document
          end

          after(:all) do
            DatabaseCleaner.clean
          end

          it 'temp_pack.name should equal TS0001 TS 201212 all' do
            expect(@temp_document.temp_pack.name).to eq('TS0001 TS 201212 all')
          end

          it { expect(@uploaded_document).to be_valid }

          describe 'temp_document' do
            subject { @temp_document }

            it { is_expected.to be_valid }
            it { is_expected.to be_persisted }
            it { expect(subject.content_file_name).to eq 'TS0001_TS_201212.pdf' }
          end
        end

        context 'when periodicity is quarterly' do
          before(:all) do
            DatabaseCleaner.start
            @user = FactoryBot.create(:user, code: 'TS0001')
            @subscription = @user.find_or_create_subscription
            @subscription.update_attribute(:period_duration, 3)
            Billing::UpdatePeriod.new(@subscription.current_period).execute
            @user.account_book_types.create(name: 'TS', description: 'TEST')
            @uploaded_document = UploadedDocument.new(@file, 'upload.pdf', @user, 'TS', 1)
            @temp_document = @uploaded_document.temp_document
          end

          after(:all) do
            DatabaseCleaner.clean
          end

          it 'temp_pack.name should equal TS0001 TS 2012T4 all' do
            expect(@temp_document.temp_pack.name).to eq('TS0001 TS 2012T4 all')
          end

          it { expect(@uploaded_document).to be_valid }

          describe 'temp_document' do
            subject { @temp_document }

            it { is_expected.to be_valid }
            it { is_expected.to be_persisted }
            it { expect(subject.position).to           eq 1 }
            it { expect(subject.delivered_by).to       eq 'TS0001' }
            it { expect(subject.delivery_type).to      eq 'upload' }
            it { expect(subject.original_file_name).to eq 'upload.pdf' }
            it { expect(subject.content_file_name).to  eq 'TS0001_TS_2012T4.pdf' }
          end
        end

        context 'when periodicity is yearly' do
          before(:all) do
            DatabaseCleaner.start
            @user = FactoryBot.create(:user, code: 'TS0001')
            @subscription = @user.find_or_create_subscription
            @subscription.update_attribute(:period_duration, 12)
            Billing::UpdatePeriod.new(@subscription.current_period).execute
            @user.account_book_types.create(name: 'TS', description: 'TEST')
            @uploaded_document = UploadedDocument.new(@file, 'upload.pdf', @user, 'TS', 1)
            @temp_document = @uploaded_document.temp_document
          end

          after(:all) do
            DatabaseCleaner.clean
          end

          it 'temp_pack.name should equal TS0001 TS 2012 all' do
            expect(@temp_document.temp_pack.name).to eq('TS0001 TS 2012 all')
          end

          it { expect(@uploaded_document).to be_valid }

          describe 'temp_document' do
            subject { @temp_document }

            it { is_expected.to be_valid }
            it { is_expected.to be_persisted }
            it { expect(subject.position).to           eq 1 }
            it { expect(subject.delivered_by).to       eq 'TS0001' }
            it { expect(subject.delivery_type).to      eq 'upload' }
            it { expect(subject.original_file_name).to eq 'upload.pdf' }
            it { expect(subject.content_file_name).to  eq 'TS0001_TS_2012.pdf' }
          end
        end
      end
    end

    context 'when extension is .tiff' do
      before(:all) do
        DatabaseCleaner.start
        Timecop.freeze(Time.local(2013,1,10))
        @user = FactoryBot.create(:user, code: 'TS0001')
        @user.create_notify
        file = File.open("#{Rails.root}/spec/support/files/upload.tiff", "r")
        @user.account_book_types.create(name: 'TS', description: 'TEST')
        @uploaded_document = UploadedDocument.new(file, 'upload.tiff', @user, 'TS', 0)
        @temp_document = @uploaded_document.temp_document
      end

      after(:all) do
        Timecop.return
        DatabaseCleaner.clean
      end

      it { expect(@uploaded_document).to be_valid }

      describe 'temp_document' do
        subject { @temp_document }

        it { is_expected.to be_valid }
        it { is_expected.to be_persisted }
        it { expect(subject.position).to           eq 1 }
        it { expect(subject.delivered_by).to       eq 'TS0001' }
        it { expect(subject.delivery_type).to      eq 'upload' }
        it { expect(subject.original_file_name).to eq 'upload.tiff' }
        it { expect(subject.content_file_name).to  eq 'TS0001_TS_201301.pdf' }
      end
    end

    describe 'when argument is not valid' do
      before(:all) do
        DatabaseCleaner.start
        Timecop.freeze(Time.local(2013,1,10))
        @user = FactoryBot.create(:user, code: 'TS0001', authd_prev_period: 0, auth_prev_period_until_day: 11)
        @journal = @user.account_book_types.create(name: 'TS', description: 'TEST')
      end

      after(:all) do
        Timecop.return
        DatabaseCleaner.clean
      end

      context 'when period 201212 are unknown' do
        before(:each) do
          @uploaded_document = UploadedDocument.new(@file, 'upload.pdf', @user, 'TS', 1)
        end

        subject { @uploaded_document }

        it { is_expected.to be_invalid }
        it { expect(subject.errors).to eq [[:invalid_period, period: '201212']] }
        it { expect(subject.full_error_messages).to eq I18n.t('activerecord.errors.models.uploaded_document.attributes.invalid_period', period: '201212') }
      end

      context 'when period 201212 are expired' do
        before(:each) do
          @user.authd_prev_period = 1
          @user.auth_prev_period_until_day = 9
          @user.save
          @uploaded_document = UploadedDocument.new(@file, 'upload.pdf', @user, 'TS', 1)
        end

        after(:all) do
          @user.authd_prev_period = 0
          @user.auth_prev_period_until_day = 11
          @user.save
        end

        subject { @uploaded_document }

        it { is_expected.to be_invalid }
        it { expect(subject.errors).to eq [[:invalid_period, period: '201212']] }
        it { expect(subject.full_error_messages).to eq I18n.t('activerecord.errors.models.uploaded_document.attributes.invalid_period', period: '201212') }
      end

      context 'when file size is too big' do
        before(:each) do
          allow(@file).to receive(:size).and_return(11_000_000)
          @uploaded_document = UploadedDocument.new(@file, 'upload.pdf', @user, 'TS', 0)
        end

        subject { @uploaded_document }

        it { is_expected.to be_invalid }
        it { expect(subject.errors).to eq [[:file_size_is_too_big, size_in_mo: '11.00']] }
        it { expect(subject.full_error_messages).to eq I18n.t('activerecord.errors.models.uploaded_document.attributes.file_size_is_too_big', size_in_mo: '11.00') }
      end

      context 'when pages number is too high' do
        before(:each) do
          allow_any_instance_of(UploadedDocument).to receive(:pages_number).and_return(101)
          @uploaded_document = UploadedDocument.new(@file, 'upload.pdf', @user, 'TS', 0)
        end

        subject { @uploaded_document }

        it { is_expected.to be_invalid }
        it { expect(subject.errors).to eq [[:pages_number_is_too_high, pages_number: 101]] }
        it { expect(subject.full_error_messages).to eq I18n.t('activerecord.errors.models.uploaded_document.attributes.pages_number_is_too_high', pages_number: 101) }
      end

      context 'when extension is invalid' do
        before(:each) do
          file = File.open("#{Rails.root}/spec/support/files/hello.txt", "r")
          @uploaded_document = UploadedDocument.new(file, 'hello.txt', @user, 'TS', 0)
          file.close
        end

        subject { @uploaded_document }

        it { is_expected.to be_invalid }
        it { expect(subject.errors).to eq [[:invalid_file_extension, extension: '.txt', valid_extensions: UploadedDocument.valid_extensions]] }
        it { expect(subject.full_error_messages).to eq I18n.t('activerecord.errors.models.uploaded_document.attributes.invalid_file_extension', extension: '.txt', valid_extensions: UploadedDocument.valid_extensions) }
      end

      context 'when file is corrupted' do
        before(:each) do
          file = File.open("#{Rails.root}/spec/support/files/corrupted.pdf", "r")
          @uploaded_document = UploadedDocument.new(file, 'upload.pdf', @user, 'TS', 0)
          file.close
        end

        subject { @uploaded_document }

        it { is_expected.to be_invalid }
        it { expect(subject.errors).to eq [[:file_is_corrupted_or_protected, nil]] }
        it { expect(subject.full_error_messages).to eq I18n.t('activerecord.errors.models.uploaded_document.attributes.file_is_corrupted_or_protected', nil) }
      end

      context 'when file is protected' do
        before(:all) do
          file = File.open("#{Rails.root}/spec/support/files/protected.pdf", "r")
          @uploaded_document = UploadedDocument.new(file, 'upload.pdf', @user, 'TS', 0)
          file.close
        end

        subject { @uploaded_document }

        it { expect(DocumentTools.modifiable?("#{Rails.root}/spec/support/files/protected.pdf")).to be_falsy }
        it { expect(DocumentTools.modifiable?(subject.temp_document.content.path)).to be_truthy }
        it { is_expected.to be_valid }
        it { expect(subject.errors).to be_empty }

      end
    end

    describe 'when journal and other arguments is not valid' do
      before(:all) do
        DatabaseCleaner.start
        Timecop.freeze(Time.local(2013,1,10))
        @user = FactoryBot.create(:user, code: 'TS0001')
        @journal = @user.account_book_types.create(name: 'TS', description: 'TEST')
      end

      after(:all) do
        Timecop.return
        DatabaseCleaner.clean
      end

      context 'when journal is unknown' do
        before(:all) do
          @journal.destroy
          @uploaded_document = UploadedDocument.new(@file, 'upload.pdf', @user, 'TS', 0)
        end

        subject { @uploaded_document }

        it { is_expected.to be_invalid }
        it { expect(subject.errors).to eq [[:journal_unknown, journal: 'TS']] }
        it { expect(subject.full_error_messages).to eq I18n.t('activerecord.errors.models.uploaded_document.attributes.journal_unknown', journal: 'TS') }
      end

      context 'when multiple arguments are invalid' do
        before(:all) do
          file = File.open("#{Rails.root}/spec/support/files/hello.txt", "r")
          @uploaded_document = UploadedDocument.new(file, 'hello.txt', @user, 'TS', 0)
          file.close
        end

        subject { @uploaded_document }

        it { is_expected.to be_invalid }
        it { expect(subject.errors).to eq [[:journal_unknown, journal: 'TS'], [:invalid_file_extension, extension: '.txt', valid_extensions: UploadedDocument.valid_extensions]] }
        describe '#full_error_messages' do
          it do
            message = []
            message << I18n.t('activerecord.errors.models.uploaded_document.attributes.journal_unknown', journal: 'TS')
            message << I18n.t('activerecord.errors.models.uploaded_document.attributes.invalid_file_extension', extension: '.txt', valid_extensions: UploadedDocument.valid_extensions)
            expect(subject.full_error_messages).to eq(message.join(', '))
          end
        end
      end
    end

    context 'when create temp_doc file with integrator', :processed_file do
      it 'create new file' do
        @user = FactoryBot.create(:user, code: 'TS0001')
        @user.account_book_types.create(name: 'TS', description: 'TEST')

        allow(Settings).to receive_message_chain('first.notify_errors_to').and_return('no')
        # allow_any_instance_of(UploadedDocument).to receive(:clean_tmp).and_return(true)

        uploaded_document = UploadedDocument.new(@file, 'upload.pdf', @user, 'TS', 0)

        expect(File.exist?(uploaded_document.processed_file.path)).to eq true
        expect(DocumentTools.completed?(uploaded_document.processed_file.path)).to eq true

        FileUtils.rm File.dirname(uploaded_document.processed_file.path), force: true
      end
    end
  end
end

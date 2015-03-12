# -*- encoding : UTF-8 -*-
require 'spec_helper'

describe UploadedDocument do
  before(:all) do
    Timecop.freeze(Time.local(2013,1,10))
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
        context 'when periodicity is monthly' do
          before(:all) do
            Timecop.freeze(Time.local(2013,1,12))
            DatabaseCleaner.start
            @user = FactoryGirl.create(:user, code: 'TS0001')
            @user.account_book_types.create(name: 'TS', description: 'TEST')
            @uploaded_document = UploadedDocument.new(@file, 'upload.pdf', @user, 'TS', 0)
            @temp_document = @uploaded_document.temp_document
          end

          after(:all) do
            DatabaseCleaner.clean
            Timecop.freeze(Time.local(2013,1,10))
          end

          it { expect(@uploaded_document).to be_valid }

          describe 'temp_document' do
            subject { @temp_document }

            it { should be_valid }
            it { should be_persisted }
            its(:position)   { should eq(1) }
            its(:delivered_by)       { should eq('TS0001') }
            its(:delivery_type)      { should eq('upload') }
            its(:original_file_name) { should eq('upload.pdf') }
            its(:content_file_name)  { should eq('TS0001_TS_201301.pdf') }
          end
        end

        context 'when periodicity is quarterly' do
          before(:all) do
            Timecop.freeze(Time.local(2013,1,12))
            DatabaseCleaner.start
            @user = FactoryGirl.create(:user, code: 'TS0001')
            @subscription = @user.find_or_create_subscription
            @subscription.update_attribute(:period_duration, 3)
            UpdatePeriodService.new(@subscription.current_period).execute
            @user.account_book_types.create(name: 'TS', description: 'TEST')
            @uploaded_document = UploadedDocument.new(@file, 'upload.pdf', @user, 'TS', 0)
            @temp_document = @uploaded_document.temp_document
          end

          after(:all) do
            DatabaseCleaner.clean
            Timecop.freeze(Time.local(2013,1,10))
          end

          it 'temp_pack.name should equal TS0001 TS 2013T1 all' do
            expect(@temp_document.temp_pack.name).to eq('TS0001 TS 2013T1 all')
          end

          it { expect(@uploaded_document).to be_valid }

          describe 'temp_document' do
            subject { @temp_document }

            it { should be_valid }
            it { should be_persisted }
            its(:position)   { should eq(1) }
            its(:delivered_by)       { should eq('TS0001') }
            its(:delivery_type)      { should eq('upload') }
            its(:original_file_name) { should eq('upload.pdf') }
            its(:content_file_name)  { should eq('TS0001_TS_2013T1.pdf') }
          end
        end
      end

      context 'when previous period is accepted' do
        context 'when periodicity is monthly' do
          before(:all) do
            DatabaseCleaner.start
            @user = FactoryGirl.create(:user, code: 'TS0001')
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

            it { should be_valid }
            it { should be_persisted }
            its(:content_file_name)  { should eq('TS0001_TS_201212.pdf') }
          end
        end

        context 'when periodicity is quarterly' do
          before(:all) do
            DatabaseCleaner.start
            @user = FactoryGirl.create(:user, code: 'TS0001')
            @subscription = @user.find_or_create_subscription
            @subscription.update_attribute(:period_duration, 3)
            UpdatePeriodService.new(@subscription.current_period).execute
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

            it { should be_valid }
            it { should be_persisted }
            its(:position)   { should eq(1) }
            its(:delivered_by)       { should eq('TS0001') }
            its(:delivery_type)      { should eq('upload') }
            its(:original_file_name) { should eq('upload.pdf') }
            its(:content_file_name)  { should eq('TS0001_TS_2012T4.pdf') }
          end
        end
      end
    end

    context 'when extension is .tiff' do
      before(:all) do
        DatabaseCleaner.start
        @user = FactoryGirl.create(:user, code: 'TS0001')
        file = File.open("#{Rails.root}/spec/support/files/upload.tiff", "r")
        @user.account_book_types.create(name: 'TS', description: 'TEST')
        @uploaded_document = UploadedDocument.new(file, 'upload.tiff', @user, 'TS', 0)
        @temp_document = @uploaded_document.temp_document
      end

      after(:all) do
        DatabaseCleaner.clean
      end

      it { expect(@uploaded_document).to be_valid }

      describe 'temp_document' do
        subject { @temp_document }

        it { should be_valid }
        it { should be_persisted }
        its(:position)   { should eq(1) }
        its(:delivered_by)       { should eq('TS0001') }
        its(:delivery_type)      { should eq('upload') }
        its(:original_file_name) { should eq('upload.tiff') }
        its(:content_file_name)  { should eq('TS0001_TS_201301.pdf') }
      end
    end

    describe 'when argument is not valid' do
      before(:all) do
        DatabaseCleaner.start
        @user = FactoryGirl.create(:user, code: 'TS0001', authd_prev_period: 0, auth_prev_period_until_day: 11)
        @journal = @user.account_book_types.create(name: 'TS', description: 'TEST')
      end

      after(:all) do
        DatabaseCleaner.clean
      end

      context 'when period 201212 are unknown' do
        before(:each) do
          @uploaded_document = UploadedDocument.new(@file, 'upload.pdf', @user, 'TS', 1)
        end

        subject { @uploaded_document }

        it { should be_invalid }
        its(:errors) { should eq([[:invalid_period, period: '201212']]) }
        its(:full_error_messages) { should eq(I18n.t('mongoid.errors.models.uploaded_document.attributes.invalid_period', period: '201212')) }
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

        it { should be_invalid }
        its(:errors) { should eq([[:invalid_period, period: '201212']]) }
        its(:full_error_messages) { should eq(I18n.t('mongoid.errors.models.uploaded_document.attributes.invalid_period', period: '201212')) }
      end

      context 'when file size are too big' do
        before(:each) do
          @file.stub(:size).and_return(52428801)
          @uploaded_document = UploadedDocument.new(@file, 'upload.pdf', @user, 'TS', 0)
        end

        subject { @uploaded_document }

        it { should be_invalid }
        its(:errors) { should eq([[:file_size_is_too_big, size_in_mo: '50.00']]) }
        its(:full_error_messages) { should eq(I18n.t('mongoid.errors.models.uploaded_document.attributes.file_size_is_too_big', size_in_mo: '50.00')) }
      end

      context 'when extension is invalid' do
        before(:each) do
          file = File.open("#{Rails.root}/spec/support/files/hello.txt", "r")
          @uploaded_document = UploadedDocument.new(file, 'hello.txt', @user, 'TS', 0)
          file.close
        end

        subject { @uploaded_document }

        it { should be_invalid }
        its(:errors) { should eq([[:invalid_file_extension, extension: '.txt', valid_extensions: UploadedDocument.valid_extensions]]) }
        its(:full_error_messages) { should eq(I18n.t('mongoid.errors.models.uploaded_document.attributes.invalid_file_extension', extension: '.txt', valid_extensions: UploadedDocument.valid_extensions)) }
      end

      context 'when file is corrupted' do
        before(:each) do
          file = File.open("#{Rails.root}/spec/support/files/corrupted.pdf", "r")
          @uploaded_document = UploadedDocument.new(file, 'upload.pdf', @user, 'TS', 0)
          file.close
        end

        subject { @uploaded_document }

        it { should be_invalid }
        its(:errors) { should eq([[:file_is_corrupted_or_protected, nil]]) }
        its(:full_error_messages) { should eq(I18n.t('mongoid.errors.models.uploaded_document.attributes.file_is_corrupted_or_protected', nil)) }
      end
    end

    describe 'when journal and other arguments is not valid' do
      before(:all) do
        DatabaseCleaner.start
        @user = FactoryGirl.create(:user, code: 'TS0001')
        @journal = @user.account_book_types.create(name: 'TS', description: 'TEST')
      end

      after(:all) do
        DatabaseCleaner.clean
      end

      context 'when journal is unknown' do
        before(:all) do
          @journal.destroy
          @uploaded_document = UploadedDocument.new(@file, 'upload.pdf', @user, 'TS', 0)
        end

        subject { @uploaded_document }

        it { should be_invalid }
        its(:errors) { should eq([[:journal_unknown, journal: 'TS']]) }
        its(:full_error_messages) { should eq(I18n.t('mongoid.errors.models.uploaded_document.attributes.journal_unknown', journal: 'TS')) }
      end

      context 'when multiple arguments are invalid' do
        before(:all) do
          file = File.open("#{Rails.root}/spec/support/files/hello.txt", "r")
          @uploaded_document = UploadedDocument.new(file, 'hello.txt', @user, 'TS', 0)
          file.close
        end

        subject { @uploaded_document }

        it { should be_invalid }
        its(:errors) { should eq([[:journal_unknown, journal: 'TS'], [:invalid_file_extension, extension: '.txt', valid_extensions: UploadedDocument.valid_extensions]]) }
        its(:full_error_messages) do
          message = []
          message << I18n.t('mongoid.errors.models.uploaded_document.attributes.journal_unknown', journal: 'TS')
          message << I18n.t('mongoid.errors.models.uploaded_document.attributes.invalid_file_extension', extension: '.txt', valid_extensions: UploadedDocument.valid_extensions)
          should eq(message.join(', '))
        end
      end
    end
  end
end

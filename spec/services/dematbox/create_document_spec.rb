# -*- encoding : UTF-8 -*-
require 'spec_helper'

describe Dematbox::CreateDocument do
  describe '.new' do
    before(:all) do
      DatabaseCleaner.start
      Timecop.freeze(Time.local(2013,1,1))

      File.open("#{Rails.root}/spec/support/files/completed.pdf", "r") do |f|
        @content64 = Base64::encode64(f.readlines.join)
      end

      @params = ActionController::Parameters.new({
        'virtualBoxId' => 'IDO%001',
        'serviceId' => '1',
        'improvedScan' => @content64,
        'docId' => '1',
        'boxId' => '1',
        'text' => nil
      })

      @organization = FactoryBot.create :organization, code: 'IDO'
      @user = FactoryBot.create(:user, code: 'IDO%001', organization: @organization)
      dematbox = Dematbox.new
      dematbox.user = @user
      service = DematboxSubscribedService.new
      service.pid = '1'
      service.is_for_current_period = true
      service.name = 'IDO'
      service2 = DematboxSubscribedService.new
      service2.pid = '2'
      service2.is_for_current_period = false
      service2.name = 'IDO'
      dematbox.services << service
      dematbox.services << service2
      dematbox.save

      Settings.create(notify_errors_to: ['jean@idocus.com'])
    end

    after(:all) do
      DatabaseCleaner.clean
      Timecop.return
    end

    context 'once' do
      context 'when arguments are valid' do
        before(:all) do
          @dematbox_document = Dematbox::CreateDocument.new(@params)
          @dematbox_document.execute
        end

        subject { @dematbox_document }

        it { is_expected.to be_valid }

        describe 'temp_document' do
          subject { @dematbox_document.temp_document }

          it { is_expected.to be_persisted }
          it { expect(subject.content_file_name).to eq('IDO%001_IDO_201301') }
        end
      end

      context 'when previous period is accepted' do
        context 'when monthly' do
          before(:all) do
            @dematbox_document = Dematbox::CreateDocument.new(@params.merge({ 'service_id' => '2' }))
            @dematbox_document.execute
          end

          subject { @dematbox_document }

          it { is_expected.to be_valid }

          describe 'temp_document' do
            subject { @dematbox_document.temp_document }

            it { is_expected.to be_persisted }
            it { expect(subject.content_file_name).to eq('IDO%001_IDO_201301') }
          end
        end

        context 'when quarterly' do
          before(:all) do
            subscription = @user.find_or_create_subscription
            subscription.update_attribute(:period_duration, 3)
            Billing::UpdatePeriod.new(subscription.current_period).execute
            @dematbox_document = Dematbox::CreateDocument.new(@params.merge({ 'service_id' => '2' }))
            @dematbox_document.execute
            subscription.periods.destroy_all
          end

          subject { @dematbox_document }

          it { is_expected.to be_valid }

          describe 'temp_document' do
            subject { @dematbox_document.temp_document }

            it { is_expected.to be_persisted }
            it { expect(subject.content_file_name).to eq('IDO%001_IDO_2013T1') }
          end
        end
      end

      context 'when previous period is not accepted' do
        context 'when monthly' do
          before(:all) do
            @user.auth_prev_period_until_day = 10
            @user.save
            Timecop.freeze(Time.local(2013,1,11))
            @dematbox_document = Dematbox::CreateDocument.new(@params.merge({ 'service_id' => '2' }))
            @dematbox_document.execute
          end

          after(:all) do
            Timecop.freeze(Time.local(2013,1,1))
          end

          subject { @dematbox_document }

          it { is_expected.to be_valid }

          describe 'temp_document' do
            subject { @dematbox_document.temp_document }

            it { is_expected.to be_persisted }
            it { expect(subject.content_file_name).to eq('IDO%001_IDO_201301') }
          end
        end

        context 'when quarterly' do
          before(:all) do
            @user.auth_prev_period_until_day = 10
            @user.save
            Timecop.freeze(Time.local(2013,1,11))
            subscription = @user.find_or_create_subscription
            subscription.update_attribute(:period_duration, 3)
            Billing::UpdatePeriod.new(subscription.current_period).execute
            @dematbox_document = Dematbox::CreateDocument.new(@params.merge({ 'service_id' => '2' }))
            @dematbox_document.execute
            subscription.periods.destroy_all
          end

          after(:all) do
            Timecop.freeze(Time.local(2013,1,1))
          end

          subject { @dematbox_document }

          it { is_expected.to be_valid }

          describe 'temp_document' do
            subject { @dematbox_document.temp_document }

            it { is_expected.to be_persisted }
            it { expect(subject.content_file_name).to eq('IDO%001_IDO_2013T1') }
          end
        end
      end

      context 'when virtual_box_id is not valid' do
        before(:all) do
          params = @params.merge({ 'virtualBoxId' => 'IDO%002' })
          @dematbox_document = Dematbox::CreateDocument.new(params)
          @dematbox_document.execute
        end

        subject { @dematbox_document }

        it { is_expected.to be_invalid }
      end

      context 'when service_id is not valid' do
        before(:all) do
          params = @params.merge({ 'serviceId' => '3' })
          @dematbox_document = Dematbox::CreateDocument.new(params)
          @dematbox_document.execute
        end

        subject { @dematbox_document }

        it { is_expected.to be_invalid }
      end

      context 'when content is not valid' do
        before(:all) do
          @dematbox_document = Dematbox::CreateDocument.new(@params.merge({ 'improvedScan' => 'CONTENT' }))
          @dematbox_document.execute
        end

        subject { @dematbox_document }

        it { is_expected.to be_invalid }
      end
    end

    context 'twice' do
      context 'when arguments are valid' do
        before(:all) do
          Dematbox::CreateDocument.new(@params).execute
          Dematbox::CreateDocument.new(@params.merge({ 'docId' => 2 })).execute
        end

        it 'should create 2 temp_documents' do
          temp_pack = TempPack.where(name: 'IDO%001 IDO 201301 all').first
          expect(temp_pack.temp_documents.count).to eq(2)
        end
      end
    end
  end
end

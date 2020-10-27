# -*- encoding : UTF-8 -*-
require 'spec_helper'

describe Billing::Period do
  before(:all) do
    @time = Time.local(2020,1,1)
  end

  describe '.new' do
    before(:all) do
      @user = FactoryBot.create(:user, code: 'TS0001')
      @subscription = Subscription.create(user_id: @user.id, period_duration: 1)
      Billing::UpdatePeriod.new(@subscription.current_period).execute
      @period_service = Billing::Period.new user: @user, current_time: @time
    end

    it { expect(@period_service.period_duration).to              eq 1 }
    it { expect(@period_service.authd_prev_period).to            eq 1 }
    it { expect(@period_service.auth_prev_period_until_day).to   eq 11.days }
    it { expect(@period_service.auth_prev_period_until_month).to eq 0.month }
    it { expect(@period_service.current_time).to                 eq @time }
  end

  describe '#start_at' do
    it 'returns 1st december 2019' do
      periods = Billing::Period.new period_duration: 1,
                                  authd_prev_period: 1,
                                  current_time: @time
      expect(periods.start_at).to eq(Time.local(2019,12,1))
    end

    it 'returns 1st november 2019' do
      periods = Billing::Period.new period_duration: 1,
                                  authd_prev_period: 2,
                                  current_time: @time
      expect(periods.start_at).to eq(Time.local(2019,11,1))
    end

    it 'returns 1st january 2019' do
      periods = Billing::Period.new period_duration: 12,
                                  authd_prev_period: 1,
                                  current_time: @time
      expect(periods.start_at).to eq(Time.local(2019,1,1))
    end
  end

  describe '#end_at' do
    it 'returns 31 january 2020' do
      periods = Billing::Period.new period_duration: 1,
                                  current_time: @time
      expect(periods.end_at).to eq(Time.local(2020,1).end_of_month)
    end

    it 'returns 31 December 2020' do
      periods = Billing::Period.new period_duration: 12,
                                  current_time: @time
      expect(periods.end_at).to eq(Time.local(2020,12).end_of_month)
    end
  end

  describe '#names' do
    it "returns ['201912', '202001']" do
      periods = Billing::Period.new period_duration:   1,
                                  authd_prev_period: 1,
                                  current_time:      @time
      expect(periods.names).to eql(['201912', '202001'])
    end

    it "returns ['202001', '202002', '202003', '202004']" do
      periods = Billing::Period.new period_duration:   1,
                                  authd_prev_period: 3,
                                  current_time:      Time.local(2020,4,30,0,0,0)
      expect(periods.names).to eql(['202001', '202002', '202003', '202004'])
    end

    it "returns ['2019', '2020']" do
      periods = Billing::Period.new period_duration:   12,
                                  authd_prev_period: 1,
                                  current_time:      @time
      expect(periods.names).to eql(['2019', '2020'])
    end

    it "returns ['2019', '2020', '2021']" do
      periods = Billing::Period.new period_duration:   12,
                                  authd_prev_period: 2,
                                  current_time:      Time.local(2021,1,15)
      expect(periods.names).to eql(['2019', '2020', '2021'])
    end
  end

  describe '#include?' do
    describe 'with time instance as parameter' do
      it 'returns true' do
        periods = Billing::Period.new period_duration: 1,
                                    authd_prev_period: 1,
                                    current_time: @time
        expect(periods.include?(Time.local(2020,1,1))).to be true
      end

      it 'returns false' do
        periods = Billing::Period.new period_duration: 1,
                                    authd_prev_period: 1,
                                    current_time: @time
        expect(periods.include?(Time.local(2019,11,1))).to be false
      end

      it 'returns true' do
        periods = Billing::Period.new period_duration: 12,
                                    authd_prev_period: 1,
                                    current_time: @time
        expect(periods.include?(Time.local(2019,1,1))).to be true
      end

      it 'returns false' do
        periods = Billing::Period.new period_duration: 12,
                                    authd_prev_period: 1,
                                    current_time: @time
        expect(periods.include?(Time.local(2018,12,31))).to be false
      end
    end

    describe 'with string instance as parameter' do
      context 'for monthly' do
        subject(:period) { Billing::Period.new period_duration: 1, authd_prev_period: 1, current_time: @time }

        it { is_expected.not_to include '202002' }
        it { is_expected.to include '202001' }
        it { is_expected.to include '201912' }
        it { is_expected.not_to include '201911' }
      end

      context 'for yearly' do
        subject(:period) { Billing::Period.new period_duration: 12, authd_prev_period: 1, current_time: @time }

        it { is_expected.not_to include '202001' }
        it { is_expected.not_to include '2020T1' }
        it { is_expected.not_to include '2018' }
        it { is_expected.to include '2019' }
        it { is_expected.to include '2020' }
        it { is_expected.not_to include '2021' }
        it { is_expected.not_to include '202101' }
        it { is_expected.not_to include '2021T1' }
      end
    end
  end

  describe '#prev_expires_at' do
    it 'returns 11 January 2020 23:59:59' do
      periods = Billing::Period.new period_duration: 1,
                                  authd_prev_period: 1,
                                  auth_prev_period_until_day: 11,
                                  auth_prev_period_until_month: 0,
                                  current_time: @time
      expect(periods.prev_expires_at).to eq(Time.local(2020,1,11).end_of_day)
    end

    it 'returns 11 January 2020 23:59:59' do
      periods = Billing::Period.new period_duration: 12,
                                  authd_prev_period: 1,
                                  auth_prev_period_until_day: 11,
                                  auth_prev_period_until_month: 0,
                                  current_time: Time.local(2020,3,20)
      expect(periods.prev_expires_at).to eq(Time.local(2020,1,11).end_of_day)
    end

    it 'returns 11 April 2020 23:59:59' do
      periods = Billing::Period.new period_duration: 12,
                                  authd_prev_period: 1,
                                  auth_prev_period_until_day: 11,
                                  auth_prev_period_until_month: 3,
                                  current_time: @time
      expect(periods.prev_expires_at).to eq(Time.local(2020,4,11).end_of_day)
    end

    it 'returns nil' do
      periods = Billing::Period.new period_duration: 1,
                                  authd_prev_period: 1,
                                  auth_prev_period_until_day: 0,
                                  auth_prev_period_until_month: 0,
                                  current_time: @time
      expect(periods.prev_expires_at).to be_nil
    end
  end
end

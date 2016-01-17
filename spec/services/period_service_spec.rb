# -*- encoding : UTF-8 -*-
require 'spec_helper'

describe PeriodService do
  before(:all) do
    @time = Time.local(2014,1,1)
  end

  describe '.new' do
    before(:all) do
      @user = FactoryGirl.create(:user, code: 'TS0001')
      @subscription = Subscription.create(user_id: @user.id, period_duration: 3)
      UpdatePeriod.new(@subscription.current_period).execute
      @period_service = PeriodService.new user: @user, current_time: @time
    end

    it { expect(@period_service.period_duration).to              eq 3 }
    it { expect(@period_service.authd_prev_period).to            eq 1 }
    it { expect(@period_service.auth_prev_period_until_day).to   eq 11.days }
    it { expect(@period_service.auth_prev_period_until_month).to eq 0.month }
    it { expect(@period_service.current_time).to                 eq @time }
  end

  describe '#start_at' do
    it 'returns 1st december 2013' do
      periods = PeriodService.new period_duration: 1,
                                  authd_prev_period: 1,
                                  current_time: @time
      expect(periods.start_at).to eq(Time.local(2013,12,1))
    end

    it 'returns 1st november 2013' do
      periods = PeriodService.new period_duration: 1,
                                  authd_prev_period: 2,
                                  current_time: @time
      expect(periods.start_at).to eq(Time.local(2013,11,1))
    end

    it 'returns 1st october 2013' do
      periods = PeriodService.new period_duration: 3,
                                  authd_prev_period: 1,
                                  current_time: @time
      expect(periods.start_at).to eq(Time.local(2013,10,1))
    end

    it 'returns 1st june 2013' do
      periods = PeriodService.new period_duration: 3,
                                  authd_prev_period: 2,
                                  current_time: @time
      expect(periods.start_at).to eq(Time.local(2013,7,1))
    end

    it 'returns 1st january 2013' do
      periods = PeriodService.new period_duration: 12,
                                  authd_prev_period: 1,
                                  current_time: @time
      expect(periods.start_at).to eq(Time.local(2013,1,1))
    end
  end

  describe '#end_at' do
    it 'returns 31 january 2014' do
      periods = PeriodService.new period_duration: 1,
                                  current_time: @time
      expect(periods.end_at).to eq(Time.local(2014,1).end_of_month)
    end

    it 'returns 31 March 2014' do
      periods = PeriodService.new period_duration: 3,
                                  current_time: @time
      expect(periods.end_at).to eq(Time.local(2014,3).end_of_month)
    end

    it 'returns 31 December 2014' do
      periods = PeriodService.new period_duration: 12,
                                  current_time: @time
      expect(periods.end_at).to eq(Time.local(2014,12).end_of_month)
    end
  end

  describe '#names' do
    it "returns ['201312', '201401']" do
      periods = PeriodService.new period_duration:   1,
                                  authd_prev_period: 1,
                                  current_time:      @time
      expect(periods.names).to eql(['201312', '201401'])
    end

    it "returns ['201401', '201402', '201403', '201404']" do
      periods = PeriodService.new period_duration:   1,
                                  authd_prev_period: 3,
                                  current_time:      Time.local(2014,4,30,0,0,0)
      expect(periods.names).to eql(['201401', '201402', '201403', '201404'])
    end

    it "returns ['2013T3', '2013T4', '2014T1']" do
      periods = PeriodService.new period_duration:   3,
                                  authd_prev_period: 2,
                                  current_time:      @time
      expect(periods.names).to eql(['2013T3', '2013T4', '2014T1'])
    end

    it "returns ['2013T4', '2014T1', '2014T2']" do
      periods = PeriodService.new period_duration:   3,
                                  authd_prev_period: 2,
                                  current_time:      Time.local(2014,4,30,0,0,0)
      expect(periods.names).to eql(['2013T4', '2014T1', '2014T2'])
    end

    it "returns ['2013', '2014']" do
      periods = PeriodService.new period_duration:   12,
                                  authd_prev_period: 1,
                                  current_time:      @time
      expect(periods.names).to eql(['2013', '2014'])
    end

    it "returns ['2013', '2014', '2015']" do
      periods = PeriodService.new period_duration:   12,
                                  authd_prev_period: 2,
                                  current_time:      Time.local(2015,1,15)
      expect(periods.names).to eql(['2013', '2014', '2015'])
    end
  end

  describe '#include?' do
    describe 'with time instance as parameter' do
      it 'returns true' do
        periods = PeriodService.new period_duration: 1,
                                    authd_prev_period: 1,
                                    current_time: @time
        expect(periods.include?(Time.local(2014,1,1))).to be true
      end

      it 'returns false' do
        periods = PeriodService.new period_duration: 1,
                                    authd_prev_period: 1,
                                    current_time: @time
        expect(periods.include?(Time.local(2013,11,1))).to be false
      end

      it 'returns true' do
        periods = PeriodService.new period_duration: 3,
                                    authd_prev_period: 1,
                                    current_time: @time
        expect(periods.include?(Time.local(2013,10,1))).to be true
      end

      it 'returns false' do
        periods = PeriodService.new period_duration: 3,
                                    authd_prev_period: 1,
                                    current_time: @time
        expect(periods.include?(Time.local(2013,9,1))).to be false
      end

      it 'returns true' do
        periods = PeriodService.new period_duration: 12,
                                    authd_prev_period: 1,
                                    current_time: @time
        expect(periods.include?(Time.local(2013,1,1))).to be true
      end

      it 'returns false' do
        periods = PeriodService.new period_duration: 12,
                                    authd_prev_period: 1,
                                    current_time: @time
        expect(periods.include?(Time.local(2012,12,31))).to be false
      end
    end

    describe 'with string instance as parameter' do
      context 'for monthly' do
        subject(:period) { PeriodService.new period_duration: 1, authd_prev_period: 1, current_time: @time }

        it { is_expected.not_to include '201402' }
        it { is_expected.to include '201401' }
        it { is_expected.to include '201312' }
        it { is_expected.not_to include '201311' }
      end

      context 'for yearly' do
        subject(:period) { PeriodService.new period_duration: 12, authd_prev_period: 1, current_time: @time }

        it { is_expected.not_to include '201401' }
        it { is_expected.not_to include '2014T1' }
        it { is_expected.not_to include '2012' }
        it { is_expected.to include '2013' }
        it { is_expected.to include '2014' }
        it { is_expected.not_to include '2015' }
        it { is_expected.not_to include '201501' }
        it { is_expected.not_to include '2015T1' }
      end
    end
  end

  describe '#prev_expires_at' do
    it 'returns 11 January 2014 23:59:59' do
      periods = PeriodService.new period_duration: 1,
                                  authd_prev_period: 1,
                                  auth_prev_period_until_day: 11,
                                  auth_prev_period_until_month: 0,
                                  current_time: @time
      expect(periods.prev_expires_at).to eq(Time.local(2014,1,11).end_of_day)
    end

    it 'returns 11 January 2014 23:59:59' do
      periods = PeriodService.new period_duration: 3,
                                  authd_prev_period: 1,
                                  auth_prev_period_until_day: 11,
                                  auth_prev_period_until_month: 0,
                                  current_time: Time.local(2014,3,20)
      expect(periods.prev_expires_at).to eq(Time.local(2014,1,11).end_of_day)
    end

    it 'returns 11 March 2014 23:59:59' do
      periods = PeriodService.new period_duration: 3,
                                  authd_prev_period: 1,
                                  auth_prev_period_until_day: 11,
                                  auth_prev_period_until_month: 2,
                                  current_time: @time
      expect(periods.prev_expires_at).to eq(Time.local(2014,3,11).end_of_day)
    end

    it 'returns 11 January 2014 23:59:59' do
      periods = PeriodService.new period_duration: 12,
                                  authd_prev_period: 1,
                                  auth_prev_period_until_day: 11,
                                  auth_prev_period_until_month: 0,
                                  current_time: Time.local(2014,3,20)
      expect(periods.prev_expires_at).to eq(Time.local(2014,1,11).end_of_day)
    end

    it 'returns 11 April 2014 23:59:59' do
      periods = PeriodService.new period_duration: 12,
                                  authd_prev_period: 1,
                                  auth_prev_period_until_day: 11,
                                  auth_prev_period_until_month: 3,
                                  current_time: @time
      expect(periods.prev_expires_at).to eq(Time.local(2014,4,11).end_of_day)
    end

    it 'returns nil' do
      periods = PeriodService.new period_duration: 1,
                                  authd_prev_period: 1,
                                  auth_prev_period_until_day: 0,
                                  auth_prev_period_until_month: 0,
                                  current_time: @time
      expect(periods.prev_expires_at).to be_nil
    end
  end
end

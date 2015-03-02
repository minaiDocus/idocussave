# -*- encoding : UTF-8 -*-
require 'spec_helper'

describe PeriodService do
  before(:all) do
    @time = Time.local(2014,1,1)
    @user = FactoryGirl.create(:user, code: 'TS0001')
    @scan_subscription = @user.find_or_create_scan_subscription
    @scan_subscription.update_attribute(:period_duration, 3)
    UpdatePeriodService.new(@scan_subscription.current_period).execute
  end

  describe '.new' do
    subject { PeriodService.new user: @user, current_time: @time }

    its(:period_duration)              { should eq(3) }
    its(:authd_prev_period)            { should eq(1) }
    its(:auth_prev_period_until_day)   { should eq(11.days) }
    its(:auth_prev_period_until_month) { should eq(0.month) }
    its(:current_time)                 { should eq(@time) }
  end

  describe '#start_at' do
    it 'return 1st december 2013' do
      periods = PeriodService.new period_duration: 1,
                                  authd_prev_period: 1,
                                  current_time: @time
      expect(periods.start_at).to eq(Time.local(2013,12,1))
    end

    it 'return 1st november 2013' do
      periods = PeriodService.new period_duration: 1,
                                  authd_prev_period: 2,
                                  current_time: @time
      expect(periods.start_at).to eq(Time.local(2013,11,1))
    end

    it 'return 1st october 2013' do
      periods = PeriodService.new period_duration: 3,
                                  authd_prev_period: 1,
                                  current_time: @time
      expect(periods.start_at).to eq(Time.local(2013,10,1))
    end

    it 'return 1st june 2013' do
      periods = PeriodService.new period_duration: 3,
                                  authd_prev_period: 2,
                                  current_time: @time
      expect(periods.start_at).to eq(Time.local(2013,7,1))
    end
  end

  describe '#end_at' do
    it 'return 31 january 2014' do
      periods = PeriodService.new period_duration: 1,
                                  current_time: @time
      expect(periods.end_at).to eq(Time.local(2014,1,1).end_of_month)
    end

    it 'return 31 March 2014' do
      periods = PeriodService.new period_duration: 3,
                                  current_time: @time
      expect(periods.end_at).to eq(Time.local(2014,1,1).end_of_quarter)
    end
  end

  describe '#names' do
    it "return ['201312', '201401']" do
      periods = PeriodService.new period_duration:   1,
                                  authd_prev_period: 1,
                                  current_time:      @time
      expect(periods.names).to eql(['201312', '201401'])
    end

    it "return ['201401', '201402', '201403', '201404']" do
      periods = PeriodService.new period_duration:   1,
                                  authd_prev_period: 3,
                                  current_time:      Time.local(2014,4,30,0,0,0)
      expect(periods.names).to eql(['201401', '201402', '201403', '201404'])
    end

    it "return ['2013T3', '2013T4', '2014T1']" do
      periods = PeriodService.new period_duration:   3,
                                  authd_prev_period: 2,
                                  current_time:      @time
      expect(periods.names).to eql(['2013T3', '2013T4', '2014T1'])
    end

    it "return ['2013T4', '2014T1', '2014T2']" do
      periods = PeriodService.new period_duration:   3,
                                  authd_prev_period: 2,
                                  current_time:      Time.local(2014,4,30,0,0,0)
      expect(periods.names).to eql(['2013T4', '2014T1', '2014T2'])
    end
  end

  describe '#include?' do
    describe 'with time instance as parameter' do
      it 'return true' do
        periods = PeriodService.new period_duration: 1,
                                    authd_prev_period: 1,
                                    current_time: @time
        expect(periods.include?(Time.local(2014,1,1))).to be_true
      end

      it 'return false' do
        periods = PeriodService.new period_duration: 1,
                                    authd_prev_period: 1,
                                    current_time: @time
        expect(periods.include?(Time.local(2013,11,1))).to be_false
      end

      it 'return true' do
        periods = PeriodService.new period_duration: 3,
                                    authd_prev_period: 1,
                                    current_time: @time
        expect(periods.include?(Time.local(2013,10,1))).to be_true
      end

      it 'return false' do
        periods = PeriodService.new period_duration: 3,
                                    authd_prev_period: 1,
                                    current_time: @time
        expect(periods.include?(Time.local(2013,9,1))).to be_false
      end
    end

    describe 'with string instance as parameter' do
      subject(:period) { PeriodService.new period_duration: 1, authd_prev_period: 1, current_time: @time }

      it { should_not include '201402' }
      it { should include '201401' }
      it { should include '201312' }
      it { should_not include '201311' }
    end
  end

  describe '#prev_expires_at' do
    it 'return 11 january 2014 23:59:59' do
      periods = PeriodService.new period_duration: 1,
                                  authd_prev_period: 1,
                                  auth_prev_period_until_day: 11,
                                  auth_prev_period_until_month: 0,
                                  current_time: @time
      expect(periods.prev_expires_at).to eq(Time.local(2014,1,11).end_of_day)
    end

    it 'return 11 March 2014 23:59:59' do
      periods = PeriodService.new period_duration: 3,
                                  authd_prev_period: 1,
                                  auth_prev_period_until_day: 11,
                                  auth_prev_period_until_month: 2,
                                  current_time: @time
      expect(periods.prev_expires_at).to eq(Time.local(2014,3,11).end_of_day)
    end

    it 'return nil' do
      periods = PeriodService.new period_duration: 1,
                                  authd_prev_period: 1,
                                  auth_prev_period_until_day: 0,
                                  auth_prev_period_until_month: 0,
                                  current_time: @time
      expect(periods.prev_expires_at).to be_nil
    end
  end

  # TODO implement me
  describe '.total_price_in_cents_wo_vat' do
  end

  describe '.vat_ratio' do
    it 'return 1.196' do
      PeriodService.vat_ratio(Time.local(2013,12,31))
    end

    it 'return 1.2' do
      PeriodService.vat_ratio(Time.local(2014,1,1))
    end
  end
end

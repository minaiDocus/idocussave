# -*- encoding : UTF-8 -*-
require 'spec_helper'

describe Period do
  it "create one period" do
    period = Period.new
    expect(period).to be_valid
    period.save
    expect(period).to be_persisted
  end

  context 'when duration is 1' do
    it '#start_at should equal 2013-02-01 00:00:00' do
      period = Period.create(duration: 1, start_at: Time.local(2013, 2, 15))
      expect(period.start_at).to eq(Time.local(2013, 2, 1))
    end

    it '#end_at should equal 2013-02-30 23:59:59' do
      period = Period.create(duration: 1, start_at: Time.local(2013, 2, 15))
      expect(period.end_at).to eq(Time.local(2013, 2).end_of_month)
    end
  end

  context 'when duration is 3' do
    it '#start_at should equal 2013-04-01 00:00:00' do
      period = Period.create(duration: 3, start_at: Time.local(2013, 5, 15))
      expect(period.start_at).to eq(Time.local(2013, 4, 1))
    end

    it '#end_at should equal 2013-06-30 23:59:59' do
      period = Period.create(duration: 3, start_at: Time.local(2013, 5, 15))
      expect(period.end_at).to eq(Time.local(2013, 6).end_of_month)
    end
  end

  describe "returns right values" do
    before(:all) do 
      @user = FactoryGirl.create(:user)
      @subscription = Subscription.create(user_id: @user.id)
    end

    subject(:period) {
      period = @subscription.periods.new

      period.max_sheets_authorized = 5
      period.unit_price_of_excess_sheet = 12

      period.max_upload_pages_authorized = 15
      period.unit_price_of_excess_upload = 6

      period.max_dematbox_scan_pages_authorized = 15
      period.unit_price_of_excess_dematbox_scan = 6

      period.max_preseizure_pieces_authorized = 5
      period.unit_price_of_excess_preseizure = 12

      period.max_expense_pieces_authorized = 5
      period.unit_price_of_excess_expense = 12

      period.pieces = 30
      period.pages = 70
      period.scanned_pieces = 10
      period.scanned_sheets = 10
      period.scanned_pages = 20
      period.dematbox_scanned_pieces = 10
      period.dematbox_scanned_pages = 20
      period.uploaded_pieces = 10
      period.uploaded_pages = 30
      period.preseizure_pieces = 10
      period.expense_pieces = 10

      period
    }

    it { expect(subject.excess_sheets).to eq(5) }
    it { expect(subject.excess_uploaded_pages).to eq(15) }
    it { expect(subject.excess_dematbox_scanned_pages).to eq(5) }
    it { expect(subject.excess_preseizure_pieces).to eq(5) }
    it { expect(subject.excess_expense_pieces).to eq(5) }

    it { expect(subject.price_in_cents_of_excess_sheets).to eq(60) }
    it { expect(subject.price_in_cents_of_excess_uploaded_pages).to eq(90) }
    it { expect(subject.price_in_cents_of_excess_dematbox_scanned_pages).to eq(30) }
    it { expect(subject.price_in_cents_of_excess_preseizures).to eq(60) }
    it { expect(subject.price_in_cents_of_excess_expenses).to eq(60) }
  end

  describe ".period_name" do
    it 'returns 201301' do
      expect(Period.period_name 1, 0, Time.local(2013,1,1)).to eq('201301')
    end

    it 'returns 201212' do
      expect(Period.period_name 1, 1, Time.local(2013,1,1)).to eq('201212')
    end

    it 'returns 201211' do
      expect(Period.period_name 1, 2, Time.local(2013,1,1)).to eq('201211')
    end

    it 'returns 2013T1' do
      expect(Period.period_name 3, 0, Time.local(2013,1,1)).to eq('2013T1')
    end

    it 'returns 2012T4' do
      expect(Period.period_name 3, 1, Time.local(2013,1,1)).to eq('2012T4')
    end

    it 'returns 2012T3' do
      expect(Period.period_name 3, 2, Time.local(2013,1,1)).to eq('2012T3')
    end

    it 'returns 201402' do
      expect(Period.period_name 1, 2, Time.local(2014,4,1)).to eq('201402')
    end

    it 'returns 2015' do
      expect(Period.period_name 12, 0, Time.local(2015,1)).to eq('2015')
    end

    it 'returns 2014' do
      expect(Period.period_name 12, 1, Time.local(2015,1)).to eq('2014')
    end

    it 'returns 2013' do
      expect(Period.period_name 12, 2, Time.local(2015,1)).to eq('2013')
    end
  end

  describe 'with Micro Package' do 
    before(:all) do
      @user = FactoryGirl.create(:user)
      @subscription = Subscription.create(
        user_id: @user.id,
        period_duration: 1,
        is_micro_package_active: true,
        start_at: Time.local(2016,1,1).beginning_of_month,
        end_at:   Time.local(2016,12,1).end_of_month,
        max_sheets_authorized:  15,
        max_upload_pages_authorized: 20,
        max_dematbox_scan_pages_authorized: 20,
        max_preseizure_pieces_authorized: 13,
        max_expense_pieces_authorized: 10,
        max_oversized_authorized: 10
      )

      1.upto(6).each do |m|
        period = Period.create(subscription: @subscription, duration: 1, start_at: Time.local(2016, m))
        
        period.unit_price_of_excess_sheet = 12
        period.scanned_sheets = 10

        period.unit_price_of_excess_upload = 6
        period.uploaded_pages = 25

        period.unit_price_of_excess_dematbox_scan = 6
        period.dematbox_scanned_pages = 10

        period.unit_price_of_excess_preseizure = 12
        period.preseizure_pieces = 6

        period.unit_price_of_excess_expense = 12
        period.expense_pieces = 3

        period.unit_price_of_excess_oversized = 100
        period.oversized = 5

        period.pieces = 10
        period.pages = 10
        period.scanned_pieces = 10
        period.uploaded_pieces = 10  
        period.dematbox_scanned_pieces = 10
        period.scanned_pages = 10
        
        period.save
      end 
    end
    context "periods withing subcription's start_at and end_date" do
      it 'Subscription#periods count should be 6' do  
        expect(@subscription.periods.size).to eq 6
      end

      describe 'current_period Time.local(2016,1)' do
        before do 
          Timecop.freeze(Time.local(2016,1))
        end
        
        describe 'Subscription' do 
          it '#current_preceeding_periods should return 0 period' do
            expect(@subscription.current_preceeding_periods.size).to eq(0) 
          end
          it '#current_period should start_at Time.local(2016,1)' do 
            expect(@subscription.current_period.start_at).to eq Time.local(2016,1) 
          end
        end

        describe 'excess' do
          subject { @subscription.current_period } 
          it { expect(subject.excess_sheets).to eq(0) }
          it { expect(subject.excess_uploaded_pages).to eq(5) }
          it { expect(subject.excess_dematbox_scanned_pages).to eq(0) }
          it { expect(subject.excess_preseizure_pieces).to eq(0) }
          it { expect(subject.excess_expense_pieces).to eq(0) }

          it { expect(subject.price_in_cents_of_excess_sheets).to eq(0) }
          it { expect(subject.price_in_cents_of_excess_uploaded_pages).to eq(30) }
          it { expect(subject.price_in_cents_of_excess_dematbox_scanned_pages).to eq(0) }
          it { expect(subject.price_in_cents_of_excess_preseizures).to eq(0) }
          it { expect(subject.price_in_cents_of_excess_expenses).to eq(0) }
        end
        after do
          Timecop.return
        end
      end

      describe 'current_period Time.local(2016,2)' do
        before do 
          Timecop.freeze(Time.local(2016,2))
        end

        describe 'Subscription' do 
          it '#current_preceeding_periods should return 1 period' do
            expect(@subscription.current_preceeding_periods.size).to eq(1) 
          end
          it '#current_period should start_at Time.local(2016,2)' do 
            expect(@subscription.current_period.start_at).to eq Time.local(2016,2) 
          end
        end

        describe 'excess' do
          subject { @subscription.current_period } 
          it { expect(subject.excess_sheets).to eq(5) }
          it { expect(subject.excess_uploaded_pages).to eq(25) }
          it { expect(subject.excess_dematbox_scanned_pages).to eq(0) }
          it { expect(subject.excess_preseizure_pieces).to eq(0) }
          it { expect(subject.excess_expense_pieces).to eq(0) }

          it { expect(subject.price_in_cents_of_excess_sheets).to eq(60) }
          it { expect(subject.price_in_cents_of_excess_uploaded_pages).to eq(150) }
          it { expect(subject.price_in_cents_of_excess_dematbox_scanned_pages).to eq(0) }
          it { expect(subject.price_in_cents_of_excess_preseizures).to eq(0) }
          it { expect(subject.price_in_cents_of_excess_expenses).to eq(0) }
        end
        after do
          Timecop.return
        end
      end

      describe 'current_period Time.local(2016,3)' do
        before do 
          Timecop.freeze(Time.local(2016,3))
        end

        describe 'Subscription' do 
          it '#current_preceeding_periods should return 2 periods' do
            expect(@subscription.current_preceeding_periods.size).to eq(2) 
          end
          it '#current_period should start_at Time.local(2016,3)' do 
            expect(@subscription.current_period.start_at).to eq Time.local(2016,3) 
          end
        end

        describe 'excess' do
          subject { @subscription.current_period } 
          it { expect(subject.excess_sheets).to eq(10) }
          it { expect(subject.excess_uploaded_pages).to eq(25) }
          it { expect(subject.excess_dematbox_scanned_pages).to eq(10) }
          it { expect(subject.excess_preseizure_pieces).to eq(5) }
          it { expect(subject.excess_expense_pieces).to eq(0) }

          it { expect(subject.price_in_cents_of_excess_sheets).to eq(120) }
          it { expect(subject.price_in_cents_of_excess_uploaded_pages).to eq(150) }
          it { expect(subject.price_in_cents_of_excess_dematbox_scanned_pages).to eq(60) }
          it { expect(subject.price_in_cents_of_excess_preseizures).to eq(60) }
          it { expect(subject.price_in_cents_of_excess_expenses).to eq(0) }
        end
        after do
          Timecop.return
        end
      end


      describe 'all periods' do
        def get_excess(value, period)
          Timecop.freeze(Time.local(2016,period))
          excess = @subscription.current_period.send(value.to_sym)
          Timecop.return
          excess
        end

        it 'total excess_sheets return 45' do
          total = 1.upto(6).map do |m| 
            get_excess(:excess_sheets, m)
          end.sum
          expect(total).to eq(45)
        end

        it 'total excess_uploaded_pages return 130' do
          total = 1.upto(6).map do |m| 
            get_excess(:excess_uploaded_pages, m)
          end.sum
          expect(total).to eq(130)
        end

        it 'total excess_dematbox_scanned_pages return 40' do
          total = 1.upto(6).map do |m| 
            get_excess(:excess_dematbox_scanned_pages, m)
          end.sum
          expect(total).to eq(40)
        end

        it 'total excess_preseizure_pieces return 23' do
          total = 1.upto(6).map do |m| 
            get_excess(:excess_preseizure_pieces, m)
          end.sum
          expect(total).to eq(23)
        end

        it 'total excess_expense_pieces return 8' do
          total = 1.upto(6).map do |m| 
            get_excess(:excess_expense_pieces, m)
          end.sum
          expect(total).to eq(8)
        end
      end
    end

    context "periods outside subscription's start_at and end_date" do 
      before(:all) do 
        @subscription.update_attributes(
          start_at: Time.local(2017,1,1).beginning_of_month,
          end_at:   Time.local(2017,12,1).end_of_month
        )
      end
      
      it 'Subscription#periods count should be 6' do
        expect(@subscription.periods.size).to eq(6)
      end
      
      it 'Subscription#current_preceeding_periods should be empty' do
        expect(@subscription.current_preceeding_periods).to be_empty
      end

      describe 'current_period Time.local(2017,1)' do
        before do 
          Timecop.freeze(Time.local(2017,1))
        end

        describe 'Subscription' do 
          it '#current_preceeding_periods should return 0 period' do
            expect(@subscription.current_preceeding_periods.size).to eq(0) 
          end
          it '#current_period should start_at Time.local(2017,1)' do 
            expect(@subscription.current_period.start_at).to eq Time.local(2017,1) 
          end
        end

        describe 'excess' do
          subject { @subscription.current_period } 
          it { expect(subject.excess_sheets).to eq(0) }
          it { expect(subject.excess_uploaded_pages).to eq(0) }
          it { expect(subject.excess_dematbox_scanned_pages).to eq(0) }
          it { expect(subject.excess_preseizure_pieces).to eq(0) }
          it { expect(subject.excess_expense_pieces).to eq(0) }
        end
        after do
          Timecop.return
        end
      end

      describe 'past_period Time.local(2016,3)' do
        before do 
          Timecop.freeze(Time.local(2016,3))
        end

        describe 'Subscription' do 
          it '#current_preceeding_periods should return 0 period' do
            expect(@subscription.current_preceeding_periods.size).to eq(0) 
          end
          it '#current_period should start_at Time.local(2016,3)' do 
            expect(@subscription.current_period.start_at).to eq Time.local(2016,3) 
          end
        end

        describe 'excess' do
          subject { @subscription.current_period } 
          it { expect(subject.excess_sheets).to eq(0) }
          it { expect(subject.excess_uploaded_pages).to eq(0) }
          it { expect(subject.excess_dematbox_scanned_pages).to eq(0) }
          it { expect(subject.excess_preseizure_pieces).to eq(0) }
          it { expect(subject.excess_expense_pieces).to eq(0) }
        end
        after do
          Timecop.return
        end
      end  
    end
  end
end

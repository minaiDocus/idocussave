require 'spec_helper'

describe 'Mini package subscription' do
  context do
    before(:each) { DatabaseCleaner.start }
    after(:each)  { DatabaseCleaner.clean }

    before(:each) do
      @organization = FactoryBot.create(:organization, code: 'IDO')
      @user = FactoryBot.create(:user, code: 'IDO%001')
      @user.options = UserOptions.create(user_id: @user.id)
      @organization.customers << @user
    end

    describe 'options' do
      it 'has pre-assignment' do
        subscription = Subscription.create(user_id: @user.id, is_mini_package_active: true)
        # subscription.set_start_date_and_end_date
        evaluator = Subscription::Evaluate.new(subscription)
        expect(evaluator).to receive(:authorize_pre_assignment)
        evaluator.execute
      end
    end

    describe '#set_start_date_and_end_date' do
      it 'start_date and end_date should be nil by default' do
        subscription = Subscription.create(user_id: @user.id, is_mini_package_active: true)

        expect(subscription.start_date).to eq nil
        expect(subscription.end_date).to eq nil
      end

      it 'should be called through EvaluateSubscription' do
        subscription = Subscription.create(user_id: @user.id, is_mini_package_active: true)
        Subscription::Evaluate.new(subscription).execute

        expect(subscription.start_date).to be_present
        expect(subscription.end_date).to be_present
      end

      context 'for monthly' do
        context 'when current date is 2016-01-01' do
          before(:each) do
            Timecop.freeze(Time.local(2016,1,1))
            @subscription = Subscription.create(user_id: @user.id, is_mini_package_active: true)
            @subscription.set_start_date_and_end_date
            Timecop.return
          end

          subject { @subscription }

          it { expect(subject.start_date).to eq Date.parse('2016-01-01') }
          it { expect(subject.end_date).to eq Date.parse('2016-12-31') }

          context 'when subscription term is reached' do
            before(:each) do
              Timecop.freeze(Time.local(2017,1,1))
              @subscription.set_start_date_and_end_date
              Timecop.return
            end

            it { expect(subject.start_date).to eq Date.parse('2017-01-01') }
            it { expect(subject.end_date).to eq Date.parse('2017-12-31') }
          end

          context 'when called a second time at a diffrent time' do
            before(:each) do
              Timecop.freeze(Time.local(2016,3,1))
              @subscription.set_start_date_and_end_date
              Timecop.return
            end

            it { expect(subject.start_date).to eq Date.parse('2016-01-01') }
            it { expect(subject.end_date).to eq Date.parse('2016-12-31') }
          end
        end

        context 'when current date is 2016-01-07' do
          before(:each) do
            Timecop.freeze(Time.local(2016,1,7))
            @subscription = Subscription.create(user_id: @user.id, is_mini_package_active: true)
            @subscription.set_start_date_and_end_date
            Timecop.return
          end

          subject { @subscription }

          it { expect(subject.start_date).to eq Date.parse('2016-01-01') }
          it { expect(subject.end_date).to eq Date.parse('2016-12-31') }
        end

        context 'when current date is 2016-02-01' do
          before(:each) do
            Timecop.freeze(Time.local(2016,2,1))
            @subscription = Subscription.create(user_id: @user.id, is_mini_package_active: true)
            @subscription.set_start_date_and_end_date
            Timecop.return
          end

          subject { @subscription }

          it { expect(subject.start_date).to eq Date.parse('2016-02-01') }
          it { expect(subject.end_date).to eq Date.parse('2017-01-31') }

          context 'when subscription term is reached' do
            before(:each) do
              Timecop.freeze(Time.local(2017,2,1))
              @subscription.set_start_date_and_end_date
              Timecop.return
            end

            it { expect(subject.start_date).to eq Date.parse('2017-02-01') }
            it { expect(subject.end_date).to eq Date.parse('2018-01-31') }
          end
        end
      end

      context 'for quaterly' do
        context 'when current date is 2016-05-01' do
          before(:each) do
            Timecop.freeze(Time.local(2016,5,1))
            @subscription = Subscription.create(user_id: @user.id, is_mini_package_active: true, period_duration: 3)
            @subscription.set_start_date_and_end_date
            Timecop.return
          end

          subject { @subscription }

          it { expect(subject.start_date).to eq Date.parse('2016-04-01') }
          it { expect(subject.end_date).to eq Date.parse('2017-03-31') }

          context 'when subscription term is reached' do
            before(:each) do
              Timecop.freeze(Time.local(2017,5,1))
              @subscription.set_start_date_and_end_date
              Timecop.return
            end

            it { expect(subject.start_date).to eq Date.parse('2017-04-01') }
            it { expect(subject.end_date).to eq Date.parse('2018-03-31') }
          end
        end
      end
    end

    context 'new subscription' do
      before(:each) do
        @subscription = Subscription.create(user_id: @user.id, is_mini_package_active: true)
        @subscription.set_start_date_and_end_date
      end

      it 'has start_date and end_date' do
        expect(@subscription.start_date).to eq @subscription.created_at.beginning_of_month.to_date
        expect(@subscription.end_date).to eq (@subscription.created_at.beginning_of_month.to_date + 1.year - 1.day)
      end

      describe 'price' do
        context 'for monthly' do
          before(:each) do
            @subscription.update_attribute(:period_duration, 1)
            @period = @subscription.current_period
          end

          it 'costs 19€ with default options' do
            Billing::UpdatePeriod.new(@period).execute
            expect(@period.price_in_cents_wo_vat).to eq 2000
          end

          it 'costs 10€ without pre-assignment active' do
            @subscription.update(is_pre_assignment_active: false)
            Billing::UpdatePeriod.new(@period).execute
            expect(@period.price_in_cents_wo_vat).to eq 1100
          end
        end

        context 'discount price', :discount_price do
          before(:each) do
            Subscription.destroy_all
            @discount = Billing::DiscountBilling.new(@organization)
          end

          it 'has iDoMini discount with iDoMini subscriptions > 75' do
            200.times { |s| Subscription.create(user_id: @user.id, is_basic_package_active: true, is_retriever_package_active: true, period_duration: 1, organization_id: @organization.id) }
            76.times { |s| Subscription.create(user_id: @user.id, is_mini_package_active: true, period_duration: 1, organization_id: @organization.id) }

            expect(@discount.title).to eq 'Remise sur CA (iDoMini : -4 € x 76)'
            expect(@discount.send(:quantity_of, :subscription)).to eq 200
            expect(@discount.total_amount_in_cents).to eq -30400.0
          end

          it 'has no discount with subscriptions < 50' do
            3.times { |s| Subscription.create(user_id: @user.id, is_basic_package_active: true, is_retriever_package_active: true, period_duration: 1, organization_id: @organization.id) }
            4.times { |s| Subscription.create(user_id: @user.id, is_mini_package_active: true, is_retriever_package_active: true, period_duration: 1, organization_id: @organization.id) }

            expect(@discount.title).to eq 'Remise sur CA (- 75 dossiers)'
            expect(@discount.send(:quantity_of, :subscription)).to eq 3
            expect(@discount.send(:quantity_of, :iDoMini)).to eq 4
            expect(@discount.send(:quantity_of, :retriever)).to eq 7
            expect(@discount.total_amount_in_cents).to eq 0.0
          end

          it 'has normal discount with iDoMini subscriptions < 75' do
            50.times { |s| Subscription.create(user_id: @user.id, is_basic_package_active: true, period_duration: 3, organization_id: @organization.id) }
            3.times { |s| Subscription.create(user_id: @user.id, is_mini_package_active: true, is_retriever_package_active: true, period_duration: 1, organization_id: @organization.id) }
            200.times { |s| Subscription.create(user_id: @user.id, is_basic_package_active: true, is_retriever_package_active: true, period_duration: 1, organization_id: @organization.id) }

            expect(@discount.title).to eq 'Remise sur CA (Abo. mensuels : -1.5 € x 200, iDofacb. : -0.5 € x 203)'
            expect(@discount.send(:quantity_of, :iDoMini)).to eq 3
            expect(@discount.total_amount_in_cents).to eq -40150.0
          end
        end
      end
    end
  end

  context 'old subscription' do
    before(:all) { DatabaseCleaner.start }
    after(:all)  { DatabaseCleaner.clean }

    before(:all) do
      @organization = FactoryBot.create(:organization)
      @user = FactoryBot.create(:user)
      @user.options = UserOptions.create(user_id: @user.id)
      @organization.customers << @user
    end

    before(:all) do
      @subscription = Subscription.create(
        user_id: @user.id,
        period_duration: 1,
        is_mini_package_active: true,
        start_date: Date.parse('2016-01-01'),
        end_date:   Date.parse('2016-12-31')
      )

      1.upto(6).each do |m|
        period = Period.create(subscription: @subscription, duration: 1, start_date: Date.parse("2016-0#{m}-01"))

        period.unit_price_of_excess_sheet = 12
        period.scanned_sheets = 16

        period.unit_price_of_excess_upload = 6
        period.uploaded_pages = 25

        period.unit_price_of_excess_dematbox_scan = 6
        period.dematbox_scanned_pages = 22

        period.unit_price_of_excess_preseizure = 12
        period.preseizure_pieces = 13

        period.unit_price_of_excess_expense = 12
        period.expense_pieces = 15

        period.unit_price_of_excess_oversized = 100
        period.oversized = 5

        period.pieces = 10
        period.pages = 10
        period.scanned_pieces = 10
        period.uploaded_pieces = 10
        period.dematbox_scanned_pieces = 10
        period.scanned_pages = 10
        period.max_sheets_authorized =  15
        period.max_upload_pages_authorized = 20
        period.max_dematbox_scan_pages_authorized = 20
        period.max_preseizure_pieces_authorized = 13
        period.max_expense_pieces_authorized = 10
        period.max_oversized_authorized = 10

        period.save
      end
    end

    context "periods withing subcription's start_date and end_date" do
      it 'Subscription#periods count should be 6' do
        expect(@subscription.periods.size).to eq 6
      end

      describe 'current_period 2016-01-01' do
        before do
          Timecop.freeze(Time.local(2016,1))
        end

        describe 'Subscription' do
          it '#current_preceeding_periods should return 0 period' do
            expect(@subscription.current_preceeding_periods(@subscription.periods.first).size).to eq(0)
          end
          it '#current_period should have start_date at 2016-01-01' do
            expect(@subscription.current_period.start_date).to eq Date.parse('2016-01-01')
          end
        end

        describe 'excess' do
          before(:each) do
            allow_any_instance_of(Period).to receive(:excess_duration).and_return(1)
          end

          subject { @subscription.current_period }
          it { expect(subject.excess_sheets).to eq(1) }
          it { expect(subject.excess_uploaded_pages).to eq(5) }
          it { expect(subject.excess_dematbox_scanned_pages).to eq(2) }
          it { expect(subject.excess_preseizure_pieces).to eq(0) }
          it { expect(subject.excess_expense_pieces).to eq(5) }

          it { expect(subject.price_in_cents_of_excess_sheets).to eq(12) }
          it { expect(subject.price_in_cents_of_excess_uploaded_pages).to eq(30) }
          it { expect(subject.price_in_cents_of_excess_dematbox_scanned_pages).to eq(12) }
          it { expect(subject.price_in_cents_of_excess_preseizures).to eq(0) }
          it { expect(subject.price_in_cents_of_excess_expenses).to eq(60) }
        end

        after do
          Timecop.return
        end
      end

      describe 'current_period 2016-02-01' do
        before do
          Timecop.freeze(Time.local(2016,2))
        end

        describe 'Subscription' do
          it '#current_preceeding_periods should return 1 period' do
            expect(@subscription.current_preceeding_periods(@subscription.periods.second).size).to eq(1)
          end
          it '#current_period should have start_date at 2016-02-01 ' do
            expect(@subscription.current_period.start_date).to eq Date.parse('2016-02-01')
          end
        end

        describe 'excess' do
          before(:each) do
            allow_any_instance_of(Period).to receive(:excess_duration).and_return(1)
          end

          subject { @subscription.current_period }
          it { expect(subject.excess_sheets).to eq(1) }
          it { expect(subject.excess_uploaded_pages).to eq(5) }
          it { expect(subject.excess_dematbox_scanned_pages).to eq(2) }
          it { expect(subject.excess_preseizure_pieces).to eq(0) }
          it { expect(subject.excess_expense_pieces).to eq(5) }

          it { expect(subject.price_in_cents_of_excess_sheets).to eq(12) }
          it { expect(subject.price_in_cents_of_excess_uploaded_pages).to eq(30) }
          it { expect(subject.price_in_cents_of_excess_dematbox_scanned_pages).to eq(12) }
          it { expect(subject.price_in_cents_of_excess_preseizures).to eq(0) }
          it { expect(subject.price_in_cents_of_excess_expenses).to eq(60) }
        end
        after do
          Timecop.return
        end
      end

      describe 'current_period 2016-03-01' do
        before do
          Timecop.freeze(Time.local(2016,3))
        end

        describe 'Subscription' do
          it '#current_preceeding_periods should return 2 period' do
            expect(@subscription.current_preceeding_periods(@subscription.periods.third).size).to eq(2)
          end
          it '#current_period should have start_date at 2016-03-01 ' do
            expect(@subscription.current_period.start_date).to eq Date.parse('2016-03-01')
          end
        end

        after do
          Timecop.return
        end
      end
    end

    context "periods outside subscription's start_date and end_date" do
      before(:all) do
        @subscription.update_attributes(
          start_date: Date.parse('2017-01-01'),
          end_date:   Date.parse('2017-12-31')
        )
      end

      it 'Subscription#periods count should be 6' do
        expect(@subscription.periods.size).to eq(6)
      end

      it 'Subscription#current_preceeding_periods should be empty' do
        expect(@subscription.current_preceeding_periods(@subscription.periods[3])).to be_empty
      end

      describe 'current_period Time.local(2017,1)' do
        before do
          Timecop.freeze(Time.local(2017,1))
        end

        describe 'Subscription' do
          it '#current_preceeding_periods should return 0 period' do
            expect(@subscription.current_preceeding_periods(@subscription.periods[4]).size).to eq(0)
          end
          it '#current_period should have start_date at 2017-01-01' do
            expect(@subscription.current_period.start_date).to eq Date.parse('2017-01-01')
          end
        end

        describe 'excess' do
          before(:each) do
            allow_any_instance_of(Period).to receive(:excess_duration).and_return(1)
          end

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

require 'spec_helper'

describe DiscountBillingService do
  context do
    before(:all) { DatabaseCleaner.start }
    after(:all)  { DatabaseCleaner.clean }

    before(:all) do
      @organization              = FactoryGirl.create(:organization)
      Subscription.create(period_duration: 1, organization_id: @organization.id)
    end

    context 'with less than 51 customers' do
      before(:all) do
        1.upto(10).each {
          user = FactoryGirl.create(:user)
          user.options = UserOptions.create(user_id: user.id)
          subscription = Subscription.create(period_duration: 1, user_id: user.id, is_basic_package_active: true)
          @organization.customers << user
          EvaluateSubscription.new(subscription).execute
        }
        @discount = DiscountBillingService.new(@organization)
      end

      after(:all) do
        @organization.customers = []
      end

      it '#subscription_quota shoud be equal to 10' do
        expect(@discount.subscription_quota).to eq(10)
      end

      it '#amount_in_cents of retriever should be equal to 0' do
        expect(@discount.amount_in_cents_of(:retriever)).to eq(0)
      end

      it '#amount_in_cents of subscription should be equal to 0' do
        expect(@discount.amount_in_cents_of(:subscription)).to eq(0)
      end

      it '#total_amount_in_cents should be equal to 0' do
        expect(@discount.total_amount_in_cents).to eq(0)
      end

      it "#title should be correct" do
        expect(@discount.title).to match(/remise sur ca \(-50 dossiers\)/i)
      end
    end

    context 'between [51,100] customers' do
      before(:all) do
        #basic_package : 50
        1.upto(50).each {
          user = FactoryGirl.create(:user)
          user.options = UserOptions.create(user_id: user.id)
          subscription = Subscription.create(period_duration: 1, user_id: user.id, is_basic_package_active: true)
          @organization.customers << user
          EvaluateSubscription.new(subscription).execute
        }
        #micro_package : 5
        1.upto(5).each {
          user = FactoryGirl.create(:user)
          user.options = UserOptions.create(user_id: user.id)
          subscription = Subscription.create(period_duration: 1, user_id: user.id, is_micro_package_active: true)
          @organization.customers << user
          EvaluateSubscription.new(subscription).execute
        }
        #retriever_package: 5
        1.upto(5).each {
          user = FactoryGirl.create(:user)
          user.options = UserOptions.create(user_id: user.id)
          subscription = Subscription.create(period_duration: 1, user_id: user.id, is_retriever_package_active: true)
          @organization.customers << user
          EvaluateSubscription.new(subscription).execute
        }
        #basic package with quaterly period: 5
        1.upto(5).each {
          user = FactoryGirl.create(:user)
          user.options = UserOptions.create(user_id: user.id)
          subscription = Subscription.create(period_duration: 3, user_id: user.id, is_basic_package_active: true)
          @organization.customers << user
          EvaluateSubscription.new(subscription).execute
        }

        @discount = DiscountBillingService.new(@organization)
      end

      after(:all) do
        @organization.customers = []
      end

      it '#subscription_quota shoud be equal to 55' do
        expect(@discount.subscription_quota).to eq(55)
      end

      it '#quatity_of retriever should be equal to 5' do
        expect(@discount.quantity_of(:retriever)).to eq(5)
      end

      it "#amount_in_cents of retriever should be equal to 0" do
        expect(@discount.amount_in_cents_of(:retriever)).to eq(0)
      end

      it "#amount_in_cents of subscription should be (1 x 55 x 100) =  -5_500" do
        expect(@discount.amount_in_cents_of(:subscription)).to eq(-5500.00)
      end

      it "#total_amount_in_cents should be equal to 5_500" do
        expect(@discount.total_amount_in_cents).to eq(-5500.00)
      end

      it "#title should be correct" do
        expect(@discount.title).to match(/remise sur ca \(abo. mensuels : -1 € x 55\)/i)
      end
    end

    context 'between [101,200] customers' do
      before(:each) do
        @discount = DiscountBillingService.new(@organization)
        allow(@discount).to receive(:quantity_of).with(:subscription).and_return(105)
        allow(@discount).to receive(:quantity_of).with(:retriever).and_return(5)
      end

      it '#unit_amount should have correct values' do
        expect(@discount.unit_amount).to eq({subscription: -1.5, retriever: -0.5})
      end

      it "#amount_in_cents of retriever should be (0.5 x 5 x 100) =  -250" do
        expect(@discount.amount_in_cents_of(:retriever)).to eq(-250)
      end

      it "#amount_in_cents of subscription should be (1.5 x 105 x 100) =  -15_750" do
        expect(@discount.amount_in_cents_of(:subscription)).to eq(-15750.00)
      end

      it "#title should be correct" do
        expect(@discount.title).to match(/remise sur ca \(abo. mensuels : -1.5 € x 105, idofacb. : -0.5 € x 5\)/i)
      end
    end

    context 'between [201,350] customers' do
      before(:each) do
        @discount = DiscountBillingService.new(@organization)
        allow(@discount).to receive(:quantity_of).with(:subscription).and_return(205)
        allow(@discount).to receive(:quantity_of).with(:retriever).and_return(5)
      end

      it '#unit_amount should have correct values' do
        expect(@discount.unit_amount).to eq({subscription: -2.0, retriever: -1.0})
      end

      it "#amount_in_cents of retriever should be (1.0 x 5 x 100) =  -500" do
        expect(@discount.amount_in_cents_of(:retriever)).to eq(-500)
      end

      it "#amount_in_cents of subscription should be (2.0 x 205 x 100) =  -41_000" do
        expect(@discount.amount_in_cents_of(:subscription)).to eq(-41000.00)
      end

      it "#title should be correct" do
        expect(@discount.title).to match(/remise sur ca \(abo. mensuels : -2 € x 205, idofacb. : -1 € x 5\)/i)
      end
    end

    context 'between [351,500] customers' do
      before(:each) do
        @discount = DiscountBillingService.new(@organization)
        allow(@discount).to receive(:quantity_of).with(:subscription).and_return(361)
        allow(@discount).to receive(:quantity_of).with(:retriever).and_return(5)
      end

      it '#unit_amount should have correct values' do
        expect(@discount.unit_amount).to eq({subscription: -3.0, retriever: -1.25})
      end

      it "#amount_in_cents of retriever should be (1.25 x 5 x 100) =  -625" do
        expect(@discount.amount_in_cents_of(:retriever)).to eq(-625)
      end

      it "#amount_in_cents of subscription should be (3.0 x 361 x 100) =  -108_300" do
        expect(@discount.amount_in_cents_of(:subscription)).to eq(-108300.00)
      end

      it "#title should be correct" do
        expect(@discount.title).to match(/remise sur ca \(abo. mensuels : -3 € x 361, idofacb. : -1.25 € x 5\)/i)
      end
    end

    context 'more than 500 customers' do
      before(:each) do
        @discount = DiscountBillingService.new(@organization)
        allow(@discount).to receive(:quantity_of).with(:subscription).and_return(650)
        allow(@discount).to receive(:quantity_of).with(:retriever).and_return(5)
      end

      it '#unit_amount should have correct values' do
        expect(@discount.unit_amount).to eq({subscription: -4.0, retriever: -1.5})
      end

      it "#amount_in_cents of retriever should be (1.5 x 5 x 100) =  -750" do
        expect(@discount.amount_in_cents_of(:retriever)).to eq(-750)
      end

      it "#amount_in_cents of subscription should be (4.0 x 650 x 100) =  -260_000" do
        expect(@discount.amount_in_cents_of(:subscription)).to eq(-260000.00)
      end

      it "#title should be correct" do
        expect(@discount.title).to match(/remise sur ca \(abo. mensuels : -4 € x 650, idofacb. : -1.5 € x 5\)/i)
      end
    end

    context 'with an organization having a reduced retriever price policy' do
      before(:each) do
        @discount = DiscountBillingService.new(@organization)
        allow(@organization).to receive_message_chain('subscription.retriever_price_option').and_return('reduced_retriever')
        allow(@discount).to receive(:quantity_of).with(:subscription).and_return(250)
        allow(@discount).to receive(:quantity_of).with(:retriever).and_return(5)
      end

      it '#retriever_price_option should return reduced_retriever' do
        expect(@organization.subscription.retriever_price_option).to eq('reduced_retriever')
      end

      it '#unit_amount should have correct values' do
        expect(@discount.unit_amount).to eq({subscription: -2.0, retriever: 0.0})
      end

      it "#amount_in_cents of retriever should be (0.0 x 5 x 100) =  0" do
        expect(@discount.amount_in_cents_of(:retriever)).to eq(0)
      end

      it "#amount_in_cents of subscription should be (2.0 x 250 x 100) =  -50_000" do
        expect(@discount.amount_in_cents_of(:subscription)).to eq(-50000.00)
      end

      it "#title should be correct" do
        expect(@discount.title).to match(/remise sur ca \(abo. mensuels : -2 € x 250\)/i)
      end
    end
  end
end
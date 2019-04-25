require 'spec_helper'

describe DiscountBillingService do
  context do
    before(:all) { DatabaseCleaner.start }
    after(:all)  { DatabaseCleaner.clean }

    before(:all) do
      @organization              = FactoryBot.create(:organization)
      Subscription.create(period_duration: 1, organization_id: @organization.id)
    end

    context "#quantity_of" do
      before(:all) do
        #basic_package : 10
        1.upto(10).each {
          user = FactoryBot.create(:user)
          user.options = UserOptions.create(user_id: user.id)
          subscription = Subscription.create(period_duration: 1, user_id: user.id, is_basic_package_active: true, is_retriever_package_active: true)
          @organization.customers << user
          EvaluateSubscription.new(subscription).execute
        }
        #scan_box_package : 5
        1.upto(5).each {
          user = FactoryBot.create(:user)
          user.options = UserOptions.create(user_id: user.id)
          subscription = Subscription.create(period_duration: 1, user_id: user.id, is_scan_box_package_active: true)
          @organization.customers << user
          EvaluateSubscription.new(subscription).execute
        }
        #retriever_package only : 3
        1.upto(3).each {
          user = FactoryBot.create(:user)
          user.options = UserOptions.create(user_id: user.id)
          subscription = Subscription.create(period_duration: 1, user_id: user.id, is_retriever_package_active: true)
          @organization.customers << user
          EvaluateSubscription.new(subscription).execute
        }
        #micro_package : 5
        1.upto(5).each {
          user = FactoryBot.create(:user)
          user.options = UserOptions.create(user_id: user.id)
          subscription = Subscription.create(period_duration: 1, user_id: user.id, is_micro_package_active: true, is_retriever_package_active: true)
          @organization.customers << user
          EvaluateSubscription.new(subscription).execute
        }
        #quaterly period: 5
        1.upto(5).each {
          user = FactoryBot.create(:user)
          user.options = UserOptions.create(user_id: user.id)
          subscription = Subscription.create(period_duration: 3, user_id: user.id, is_basic_package_active: true, is_retriever_package_active: true)
          @organization.customers << user
          EvaluateSubscription.new(subscription).execute
        }

        @discount = DiscountBillingService.new(@organization)
      end

      after(:all) do
        @organization.customers = []
      end

      it 'subscription should be equal to 15' do
        expect(@discount.quantity_of(:subscription)).to eq(15)
      end
      
      it 'retriever should be equal to 13' do
        expect(@discount.quantity_of(:retriever)).to eq(13)
      end
    end

    context 'quota' do
      context 'less than 51' do
        before(:each) do
          @discount = DiscountBillingService.new(@organization)
          allow(@discount).to receive(:quantity_of).with(:subscription).and_return(10)
          allow(@discount).to receive(:quantity_of).with(:retriever).and_return(10)
        end

        it "#amount_in_cents of subscription should be 0" do
          expect(@discount.amount_in_cents_of(:subscription)).to eq(0)
        end

        it "#amount_in_cents of retriever should be 0" do
          expect(@discount.amount_in_cents_of(:retriever)).to eq(0)
        end

        it "#title should be correct" do
          expect(@discount.title).to match(/remise sur CA \(-50 dossiers\)/i)
        end
      end

      context 'subscription = 60 and retriever = 50' do
        before(:each) do
          @discount = DiscountBillingService.new(@organization)
          allow(@discount).to receive(:quantity_of).with(:subscription).and_return(60)
          allow(@discount).to receive(:quantity_of).with(:retriever).and_return(50)
        end

        it "#amount_in_cents of subscription should be (1 x 60 x 100) =  -6_000" do
          expect(@discount.amount_in_cents_of(:subscription)).to eq(-6_000.00)
        end

        it "#amount_in_cents of retriever should be (0.0 x 50 x 100) =  0" do
          expect(@discount.amount_in_cents_of(:retriever)).to eq(0)
        end

        it "#title should be correct" do
          expect(@discount.title).to match(/remise sur ca \(abo. mensuels : -1 € x 60\)/i)
        end
      end

      context 'subscription = 45 and retriever = 205' do
        before(:each) do
          @discount = DiscountBillingService.new(@organization)
          allow(@discount).to receive(:quantity_of).with(:subscription).and_return(45)
          allow(@discount).to receive(:quantity_of).with(:retriever).and_return(205)
        end

        it "#amount_in_cents of subscription should be (0 x 45 x 100) =  0" do
          expect(@discount.amount_in_cents_of(:subscription)).to eq(0)
        end

        it "#amount_in_cents of retriever should be (1 x 205 x 100) =  -20_500" do
          expect(@discount.amount_in_cents_of(:retriever)).to eq(-20_500)
        end

        it "#title should be correct" do
          expect(@discount.title).to match(/remise sur ca \(idofacb. : -1 € x 205\)/i)
        end
      end
    end

    context 'with special cases : ' do
      describe 'an organization having a reduced retriever price policy' do
        before(:each) do
          @discount = DiscountBillingService.new(@organization)
          allow(@organization).to receive_message_chain('subscription.retriever_price_option').and_return('reduced_retriever')
          allow(@discount).to receive(:quantity_of).with(:subscription).and_return(250)
          allow(@discount).to receive(:quantity_of).with(:retriever).and_return(205)
        end

        it '#retriever_price_option should return reduced_retriever' do
          expect(@organization.subscription.retriever_price_option).to eq('reduced_retriever')
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

      describe 'an organization having special discount policy' do
        before(:each) do
          @discount = DiscountBillingService.new(@organization)
          @organization.code = 'GMBA'
          allow(@discount).to receive(:quantity_of).with(:subscription).and_return(45)
          allow(@discount).to receive(:quantity_of).with(:retriever).and_return(251)
        end

        it '#apply_special_policy?' do
          expect(@discount.apply_special_policy?).to be true
        end

        it "#amount_in_cents of retriever should be (1.25 x 251 x 100) =  -31_375" do
          expect(@discount.amount_in_cents_of(:retriever)).to eq(-31_375)
        end

        it "#amount_in_cents of subscription should be (1 x 45 x 100) =  -4_500" do
          expect(@discount.amount_in_cents_of(:subscription)).to eq(-4_500.00)
        end

        it "#title should be correct" do
          expect(@discount.title).to match(/remise sur ca \(abo. mensuels : -1 € x 45, idofacb. : -1.25 € x 251\)/i)
        end
      end

    end
  end
end
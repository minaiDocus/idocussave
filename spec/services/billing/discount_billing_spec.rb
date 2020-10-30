require 'spec_helper'

describe Billing::DiscountBilling do
  context do
    before(:all) { DatabaseCleaner.start }
    after(:all)  { DatabaseCleaner.clean }

    before(:all) do
      @organization              = FactoryBot.create(:organization)
      Subscription.create(period_duration: 1, organization_id: @organization.id)
    end

    context "#quantity_of" do
      before(:all) do
        1.upto(10).each {
          user = FactoryBot.create(:user)
          user.options = UserOptions.create(user_id: user.id)
          subscription = Subscription.create(period_duration: 1, user_id: user.id, is_basic_package_active: true, is_retriever_package_active: true)
          @organization.customers << user
          Subscription::Evaluate.new(subscription).execute
        }
        #ido_x : 5
        1.upto(5).each {
          user = FactoryBot.create(:user)
          user.options = UserOptions.create(user_id: user.id)
          subscription = Subscription.create(period_duration: 1, user_id: user.id, is_idox_package_active: true)
          @organization.customers << user
          Subscription::Evaluate.new(subscription).execute
        }
        1.upto(3).each {
          user = FactoryBot.create(:user)
          user.options = UserOptions.create(user_id: user.id)
          subscription = Subscription.create(period_duration: 1, user_id: user.id, is_retriever_package_active: true)
          @organization.customers << user
          Subscription::Evaluate.new(subscription).execute
        }
        #micro_package : 5
        1.upto(5).each {
          user = FactoryBot.create(:user)
          user.options = UserOptions.create(user_id: user.id)
          subscription = Subscription.create(period_duration: 1, user_id: user.id, is_micro_package_active: true, is_retriever_package_active: true)
          @organization.customers << user
          Subscription::Evaluate.new(subscription).execute
        }

        @discount = Billing::DiscountBilling.new(@organization)
      end

      after(:all) do
        @organization.customers = []
      end

      it 'subscription should be equal to 15' do
        expect(@discount.quantity_of(:subscription)).to eq(10)
      end
      
      it 'retriever should be equal to 13' do
        expect(@discount.quantity_of(:retriever)).to eq(13)
      end
    end

    context 'quota' do
      context 'less than 51' do
        before(:each) do
          @discount = Billing::DiscountBilling.new(@organization)
          allow(@discount).to receive(:quantity_of).with(:subscription).and_return(10)
          allow(@discount).to receive(:quantity_of).with(:retriever).and_return(10)
          allow(@discount).to receive(:quantity_of).with(:iDoMini).and_return(10)
        end

        it "#amount_in_cents of subscription should be 0" do
          expect(@discount.amount_in_cents_of(:subscription)).to eq(0)
        end

        it "#amount_in_cents of retriever should be 0" do
          expect(@discount.amount_in_cents_of(:retriever)).to eq(0)
        end

        it "#title should be correct" do
          expect(@discount.title).to match /Remise sur CA \(- 75 dossiers\)/
        end
      end

      context 'subscription = 80, retriever = 70 and idomini = 50' do
        before(:each) do
          @discount = Billing::DiscountBilling.new(@organization)
        end

        it "#amount_in_cents of subscription should be (1 x 80 x 100) =  -8_000" do
          allow_any_instance_of(Billing::DiscountBilling).to receive(:quantity_of).with(:subscription).and_return(80)
          allow_any_instance_of(Billing::DiscountBilling).to receive(:classic_quantity_of).with(:subscription).and_return(80)
          expect(@discount.amount_in_cents_of(:subscription)).to eq(-8_000)
        end

        it "#amount_in_cents of retriever should be (0.0 x 70 x 100) =  0" do
          allow_any_instance_of(Billing::DiscountBilling).to receive(:quantity_of).with(:retriever).and_return(70)
          expect(@discount.amount_in_cents_of(:retriever)).to eq(0)
        end

        it "#amount_in_cents of idomini should be (4 x 50 x 100) =  -20_000" do
          allow_any_instance_of(Billing::DiscountBilling).to receive(:quantity_of).with(:iDoMini).and_return(50)
          allow_any_instance_of(Billing::DiscountBilling).to receive(:classic_quantity_of).with(:iDoMini).and_return(50)
          expect(@discount.amount_in_cents_of(:iDoMini)).to eq(-20_000)
        end

        it "#title should be correct" do
          allow_any_instance_of(Billing::DiscountBilling).to receive(:quantity_of).with(:subscription).and_return(80)
          allow_any_instance_of(Billing::DiscountBilling).to receive(:unit_amount).with(:subscription).and_return(-1)
          allow_any_instance_of(Billing::DiscountBilling).to receive(:unit_amount).with(:retriever).and_return(0)
          allow_any_instance_of(Billing::DiscountBilling).to receive(:classic_quantity_of).with(:subscription).and_return(80)
          allow_any_instance_of(Billing::DiscountBilling). to receive(:is_iDoMini_discount?).and_return(false)
          expect(@discount.title).to match(/remise sur ca \(abo. mensuels : -1 € x 80\)/i)
        end
      end

      context 'subscription = 45 and retriever = 351' do
        before(:each) do
          @discount = Billing::DiscountBilling.new(@organization)
          allow(@discount).to receive(:quantity_of).with(:subscription).and_return(45)
          allow(@discount).to receive(:quantity_of).with(:retriever).and_return(351)
        end

        it "#amount_in_cents of subscription should be (0 x 45 x 100) =  0" do
          expect(@discount.amount_in_cents_of(:subscription)).to eq(0)
        end

        it "#amount_in_cents of retriever should be (1 x 351 x 100) =  -35_100" do
          allow_any_instance_of(Billing::DiscountBilling).to receive(:classic_quantity_of).with(:retriever).and_return(351)
          expect(@discount.amount_in_cents_of(:retriever)).to eq(-35_100)
        end

        it "#title should be correct" do
          allow_any_instance_of(Billing::DiscountBilling). to receive(:is_iDoMini_discount?).and_return(false)
          allow_any_instance_of(Billing::DiscountBilling).to receive(:unit_amount).with(:subscription).and_return(0)
          allow_any_instance_of(Billing::DiscountBilling).to receive(:unit_amount).with(:retriever).and_return(-1)
          allow_any_instance_of(Billing::DiscountBilling).to receive(:classic_quantity_of).with(:retriever).and_return(351)
          expect(@discount.title).to match(/remise sur ca \(idofacb. : -1 € x 351\)/i)
        end
      end
    end

    context 'with special cases : ' do
      describe 'an organization having a reduced retriever price policy' do
        before(:each) do
          @discount = Billing::DiscountBilling.new(@organization)
          allow(@organization).to receive_message_chain('subscription.retriever_price_option').and_return('reduced_retriever')
          allow(@discount).to receive(:quantity_of).with(:subscription).and_return(250)
          allow(@discount).to receive(:quantity_of).with(:retriever).and_return(205)
          allow(@discount).to receive(:quantity_of).with(:iDoMini).and_return(0)
        end

        it '#retriever_price_option should return reduced_retriever' do
          expect(@organization.subscription.retriever_price_option).to eq('reduced_retriever')
        end

        it "#amount_in_cents of retriever should be (0.0 x 5 x 100) =  0" do
          expect(@discount.amount_in_cents_of(:retriever)).to eq(0)
        end

        it "#amount_in_cents of subscription should be (2.5 x 250 x 100) =  -62_500" do
          allow_any_instance_of(Billing::DiscountBilling).to receive(:apply_special_policy?).and_return(true)
          allow_any_instance_of(Billing::DiscountBilling).to receive(:classic_quantity_of).with(:subscription).and_return(250)
          expect(@discount.amount_in_cents_of(:subscription)).to eq(-62_500)
        end

        it "#title should be correct" do
          allow_any_instance_of(Billing::DiscountBilling).to receive(:apply_special_policy?).and_return(true)
          allow_any_instance_of(Billing::DiscountBilling). to receive(:is_iDoMini_discount?).and_return(false)
          allow_any_instance_of(Billing::DiscountBilling).to receive(:unit_amount).with(:subscription).and_return(-2.5)
          allow_any_instance_of(Billing::DiscountBilling).to receive(:unit_amount).with(:retriever).and_return(0)
          allow_any_instance_of(Billing::DiscountBilling).to receive(:classic_quantity_of).with(:subscription).and_return(250)
          expect(@discount.title).to match(/remise sur ca \(abo. mensuels : -2.5 € x 250\)/i)
        end
      end

      describe 'an organization having special discount policy' do
        before(:each) do
          @discount = Billing::DiscountBilling.new(@organization)
          @organization.code = 'FIDA'
          allow_any_instance_of(Billing::DiscountBilling).to receive(:apply_special_policy?).and_return(true)
          allow(@discount).to receive(:quantity_of).with(:subscription).and_return(75)
          allow(@discount).to receive(:quantity_of).with(:retriever).and_return(251)
          allow(@discount).to receive(:quantity_of).with(:iDoMini).and_return(10)
        end

        it '#apply_special_policy?' do
          expect(@discount.apply_special_policy?).to be true
        end

        it "#amount_in_cents of retriever should be (1.25 x 251 x 100) =  -31_375" do
          allow_any_instance_of(Billing::DiscountBilling).to receive(:classic_quantity_of).with(:retriever).and_return(251)
          expect(@discount.amount_in_cents_of(:retriever)).to eq(-31_375)
        end

        it "#amount_in_cents of subscription should be (1.5 x 75 x 100) =  -11_250" do
          allow_any_instance_of(Billing::DiscountBilling).to receive(:classic_quantity_of).with(:subscription).and_return(75)
          expect(@discount.amount_in_cents_of(:subscription)).to eq(-11_250)
        end

        it "#title should be correct" do
          allow_any_instance_of(Billing::DiscountBilling).to receive(:apply_special_policy?).and_return(true)
          allow_any_instance_of(Billing::DiscountBilling). to receive(:is_iDoMini_discount?).and_return(false)
          allow_any_instance_of(Billing::DiscountBilling).to receive(:unit_amount).with(:subscription).and_return(-1.5)
          allow_any_instance_of(Billing::DiscountBilling).to receive(:unit_amount).with(:retriever).and_return(-1.25)
          allow_any_instance_of(Billing::DiscountBilling).to receive(:classic_quantity_of).with(:subscription).and_return(75)
          allow_any_instance_of(Billing::DiscountBilling).to receive(:classic_quantity_of).with(:retriever).and_return(251)
          expect(@discount.title).to match(/Remise sur CA \(Abo. mensuels : -1.5 € x 75, iDofacb. : -1.25 € x 251\)/i)
        end
      end

    end
  end
end
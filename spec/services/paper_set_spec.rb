# -*- encoding : UTF-8 -*-
require 'spec_helper'
Sidekiq::Testing.inline! #execute jobs immediatly

describe Order::PaperSet do
  def customer
    @customer = FactoryBot.create(:user)
  end

  def address_attributes
    {
      first_name: "test", last_name: "test",
      email: nil, company: "test", company_number: nil, address_1: "12test",
      address_2: "", city: "test", zip: "75001", state: nil, country: nil, building: nil,
      place_called_or_postal_box: nil, door_code: nil, other: nil, phone: nil, phone_mobile: nil, is_for_billing: false,
      is_for_paper_return: false, is_for_paper_set_shipping: false, is_for_dematbox_shipping: false
    }
  end

  def create_order(params)
    collaborator = FactoryBot.create(:user, is_prescriber: true)

    @customer.options = UserOptions.create(user_id: @customer.id)

    organization = Organization.create name: params[:name], code: params[:code], leader_id: collaborator.id
    organization.customers << @customer

    Subscription.create(period_duration: 1, current_packages: '["ido_classique", "pre_assignment_option"]', number_of_journals: 5, organization_id: nil, user_id: @customer.id)

    FactoryBot.create(:account_book_type, :journal_with_preassignment, user_id: @customer.id, name: 'AC', description: '( Achat )')

    order = Order.new(params[:order])
  end

  context 'Paper set order prices' do
    before(:each) do
       DatabaseCleaner.start
      Timecop.freeze(Time.local(2021,06,1))
    end

    after(:each) do
      Timecop.return
      DatabaseCleaner.clean
    end

    it 'specific paper set order price', :manual_order do
      customer

      params = {
        name: 'iDocus',
        code: 'IDOC',
        order: {
          type: "paper_set", vat_ratio: 1.2, 
          dematbox_count: 0, period_duration: 1, paper_set_casing_size: 0, paper_set_folder_count: 8, 
          paper_set_start_date: "2021-06-01", paper_set_end_date: "2021-12-01",
          user_id: @customer.id,
          address_attributes: address_attributes,
          paper_return_address_attributes: address_attributes
        }
      }

      order = create_order(params)


      Order::PaperSet.new(@customer, order).execute

      order.reload


      expect(order.normal_paper_set_order?).to be false
      expect(order.paper_set_casing_size).to eq 0
      expect(order.state).to eq 'confirmed'
      expect(order.price_in_cents_wo_vat).to eq 2100 # 3 * 7
      expect(order.address.is_for_paper_set_shipping).to be true
    end

    it 'normal paper set order price', :auto_mailing_order do
      customer

      Settings.create(notify_paper_set_order_to: 'test@idocus.fr')

      params = {
        name: 'accomplys',
        code: 'ACC',
        order: {
          type: "paper_set", vat_ratio: 1.2, 
          dematbox_count: 0, period_duration: 1, paper_set_casing_size: 500,
          paper_set_casing_count: 4, paper_set_folder_count: 5, 
          paper_set_start_date: "2021-06-01", paper_set_end_date: "2021-12-01",
          user_id: @customer.id,
          address_attributes: address_attributes,
          paper_return_address_attributes: address_attributes
        }
      }

      order = create_order(params)


      Order::PaperSet.new(@customer, order).execute

      order.reload


      expect(order.normal_paper_set_order?).to be true
      expect(order.paper_set_casing_size).to eq 500
      expect(order.paper_set_casing_count).to eq 4
      expect(order.state).to eq 'confirmed'
      expect(order.price_in_cents_wo_vat).to eq 6100
      expect(order.address.is_for_paper_set_shipping).to be true

      mail = ActionMailer::Base.deliveries.last

      expect(mail.to).to eq ['test@idocus.fr']
      expect(mail.subject).to eq "Commande de Kit envoi courrier"
      expect(mail.body.encoded).to include "vient de passer une commande d'un Kit envoi courrier avec les caractéristiques suivantes :"
    end
  end
end
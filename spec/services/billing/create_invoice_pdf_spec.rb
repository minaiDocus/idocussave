# -*- encoding : UTF-8 -*-
require 'spec_helper'

describe Billing::CreateInvoicePdf do
  def create_bank_account_with_operation(user, i=8, month=2)
    bank_account = BankAccount.create(
      bank_name: "Allianz-#{i}", name: "Allianz-#{i}", number: "456654546#{i}",
      user: user, api_id: "456654546#{i}", api_name: 'capidocus', journal: 'BQ', currency: 'EUR',
      original_currency: {"id"=>"EUR", "symbol"=>"€", "prefix"=>false, "precision"=>2, "marketcap"=>nil, "datetime"=>nil, "name"=>"Euro"},
      is_used: true, accounting_number: "512000", temporary_account: '471000',
      start_date: '2020-03-02', type_name: "unknown-#{i}", lock_old_operation: true, permitted_late_days: 12
    )

    Operation.create(
      created_at: "2020-03-01 21:00:00", updated_at: "2020-03-01 21:00:00",
      date: "2020-0#{month}-02", value_date: "2020-0#{month}-02", transaction_date: "2020-0#{month}-02", label: "SARL 231E47", amount: 500.0,
      category: "Autres recettes", processed_at: "2020-0#{month}-02 04:30:51",
      is_locked: nil, organization_id: user.organization.id, user_id: user.id, bank_account_id: bank_account.id,
      api_id: "456654546#{i}", api_name: "capidocus",
      is_coming: false, deleted_at: nil, forced_processing_at: nil, forced_processing_by_user_id: nil, currency: {}
    )
  end

  before(:all) do
    Timecop.freeze(Time.local(2020,04,15))
    DatabaseCleaner.start

    2.times do |i|
      organization = create :organization, code: "TS#{i}"
      Subscription.create(period_duration: 1, tva_ratio: 1.2, user_id: nil, organization_id: organization.id)
      Address.create(first_name: 'Test', last_name: 'Test', company: "TS#{i}", address_1: 'abc rue abc', city: 'Paris', zip: 75113, country: 'France', is_for_billing: true, locatable_type: 'Organization', locatable_id: organization.id)
      organization.subscription.find_or_create_period(Date.today - 1.month)

      users = [
                { email: "user1#{i}@idocus.com", password: '123456', code: "TS#{i}%A1#{i}", first_name: "f_name1#{i}", last_name: "l_name1#{i}", phone_number: "123", company: "Organization" },
                { email: "user2#{i}@idocus.com", password: '123456', code: "TS#{i}%B2#{i}", first_name: "f_name2#{i}", last_name: "l_name2#{i}", phone_number: "123", company: "Organization" }
              ]
      users.each do |_user|
        user = User.new(_user)
        user.organization = organization
        user.save

        user.account_book_types.create(name: "AC", description: "AC (Achats)", position: 1, entry_type: 2, currency: "EUR", domain: "AC - Achats", account_number: "0ACC", charge_account: "471000", vat_accounts: {'20':'445660', '8.5':'153141', '13':'754213'}.to_json, anomaly_account: "471000", is_default: true, is_expense_categories_editable: true, organization_id: organization.id)
        Subscription.create(period_duration: 1, current_packages: '["ido_classique", "pre_assignment_option"]', number_of_journals: 5, organization_id: nil, user_id: user.id)

        user.subscription.find_or_create_period(Date.today - 1.month)
      end
    end
  end

  after(:all) do
    Timecop.return
    DatabaseCleaner.clean
  end

  before(:each) do
    allow_any_instance_of(Billing::UpdatePeriodData).to receive(:execute).and_return(true)
    allow_any_instance_of(Billing::UpdateOrganizationPeriod).to receive(:fetch_all).and_return(true)
    allow(Billing::DiscountBilling).to receive(:update_period).and_return(true)
    Invoice.destroy_all
  end

  it 'generates pdf invoices - successfully', :generate do
    Billing::CreateInvoicePdf.for_all

    invoices = Invoice.all

    expect(invoices.size).to eq 2
    expect(File.exist?(invoices.first.cloud_content_object.reload.path)).to be true
    expect(invoices.collect(&:organization_id)).to eq Organization.all.collect(&:id)
    expect(invoices.first.amount_in_cents_w_vat).to eq 4800
  end

  it 'creates a single invoice (for a specific organization)' do
    Billing::CreateInvoicePdf.for Organization.first.id

    invoices = Invoice.all

    expect(invoices.size).to eq 1
    expect(invoices.first.organization).to eq Organization.first
    expect(File.exist?(invoices.first.cloud_content_object.reload.path)).to be true
    expect(invoices.first.amount_in_cents_w_vat).to eq 4800
  end

  it 'updates an existing invoice', :update_invoice do
    Billing::CreateInvoicePdf.for_all

    invoice_1 = Invoice.first
    md5_1     = DocumentTools.checksum(invoice_1.cloud_content_object.reload.path)

    org = Organization.first
    customer = org.customers.first
    period = customer.subscription.periods.order(created_at: :asc).first
    period.current_packages = ['retriever_option']
    period.save

    Billing::CreateInvoicePdf.for org, invoice_1.number

    invoice_2 = Invoice.first
    md5_2     = DocumentTools.checksum(invoice_2.cloud_content_object.reload.path)

    expect(Invoice.all.size).to eq 2
    expect(invoice_1.number == invoice_2.number).to be true
    expect(invoice_1.organization == invoice_2.organization).to be true
    expect(md5_1 != md5_2).to be true
    expect(invoice_1.amount_in_cents_w_vat).to eq 4800
    expect(invoice_2.amount_in_cents_w_vat).to eq 3000
  end

  it 'generates correct packages/options price from period', :test_package do
    user         = User.last
    subscription = user.subscription
    period       = subscription.periods.order(created_at: :asc).first
    period.set_current_packages

    subscription.update(futur_packages: '["ido_micro"]')

    Billing::CreateInvoicePdf.for_all

    invoice = Invoice.last

    expect(period.reload.get_active_packages).to eq [:ido_classique]
    expect(period.product_option_orders.size).to eq 2
    expect(period.product_option_orders.first.name).to eq 'basic_package_subscription'
    expect(period.product_option_orders.second.name).to eq 'pre_assignment_option'
    expect(invoice.amount_in_cents_w_vat).to eq 4800
  end

  it 'generates excess bank account options', :bank_account do
    user         = User.last
    subscription = user.subscription
    period       = subscription.periods.order(created_at: :asc).first
    period.set_current_packages

    5.times do |i|
      create_bank_account_with_operation(user, i, 3)
    end

    Billing::CreateInvoicePdf.for_all

    invoice = Invoice.last

    expect(period.reload.get_active_packages).to eq [:ido_classique]
    expect(period.product_option_orders.size).to eq 3
    expect(period.product_option_orders.first.name).to eq 'basic_package_subscription'
    expect(period.product_option_orders.second.name).to eq 'pre_assignment_option'
    expect(period.product_option_orders.third.name).to eq 'excess_bank_accounts'
    expect(period.product_option_orders.third.quantity).to eq 3
    expect(period.product_option_orders.last.price_in_cents_wo_vat).to eq 3*200.0
    expect(invoice.amount_in_cents_w_vat).to eq 5520
  end

  it 'generates operation options from any previous periods', :billing_history do
    BankAccount.destroy_all
    user         = User.last
    subscription = user.subscription
    period       = subscription.periods.order(created_at: :asc).first
    period.set_current_packages

    create_bank_account_with_operation(user)

    Billing::CreateInvoicePdf.for_all

    invoice = Invoice.last

    expect(period.reload.get_active_packages).to eq [:ido_classique]
    expect(period.product_option_orders.size).to eq 3
    expect(period.product_option_orders.first.name).to eq 'basic_package_subscription'
    expect(period.product_option_orders.second.name).to eq 'pre_assignment_option'
    expect(period.product_option_orders.last.name).to eq 'billing_previous_operations'
    expect(period.product_option_orders.last.price_in_cents_wo_vat).to eq 5*100.0
    expect(period.product_option_orders.last.title).to match /mois de février/
    expect(invoice.amount_in_cents_w_vat).to eq 5400
  end
end
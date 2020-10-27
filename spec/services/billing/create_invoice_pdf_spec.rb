# -*- encoding : UTF-8 -*-
require 'spec_helper'

describe Billing::CreateInvoicePdf do
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

        user.account_book_types.create(name: "AC", description: "AC (Achats)", position: 1, entry_type: 2, currency: "EUR", domain: "AC - Achats", account_number: "0ACC", charge_account: "471000", vat_account: "445660", anomaly_account: "471000", is_default: true, is_expense_categories_editable: true, organization_id: organization.id)
        Subscription.create(period_duration: 1, is_basic_package_active: true, number_of_journals: 5, organization_id: 0, user_id: user.id)
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

    subscription.update({ is_basic_package_to_be_disabled: true, is_micro_package_active: true })

    Billing::CreateInvoicePdf.for_all

    invoice = Invoice.last

    expect(period.reload.get_active_packages).to eq [:ido_classique]
    expect(period.product_option_orders.size).to eq 2
    expect(period.product_option_orders.first.name).to eq 'basic_package_subscription'
    expect(period.product_option_orders.second.name).to eq 'pre_assignment_option'
    expect(invoice.amount_in_cents_w_vat).to eq 4800
  end
end
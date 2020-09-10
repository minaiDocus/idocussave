# -*- encoding : UTF-8 -*-
require 'spec_helper'

describe Api::Sgi::V1::MappingGeneratorController, :type => :controller do
  before(:all) do
    DatabaseCleaner.start
    Timecop.freeze(Time.local(2020,9,9))

    organization = FactoryBot.create :organization, code: 'IDO'
    @admin = FactoryBot.create :user, :admin, code: 'IDO%0001', organization_id: organization.id
    @token = 'Token 123'
    @admin.authentication_token = @token 
    @admin.save

    @user = FactoryBot.create :user, code: 'IDO%0002', organization_id: organization.id

    FactoryBot.create(:account_book_type, :journal_with_preassignment, user_id: @user.id, name: 'AC', description: '( Achat )')

    @accounting_plan = AccountingPlan.new
    @accounting_plan.user = @user

    item = AccountingPlanItem.new
    item.third_party_name    = 'iDocus'
    item.third_party_account = '0IDOC'
    item.conterpart_account  = '1234'
    item.kind                = 'provider'
    item.save
    @accounting_plan.providers << item

    item = AccountingPlanItem.new
    item.third_party_name    = 'iDocus2'
    item.third_party_account = '0IDOC2'
    item.conterpart_account  = '5678'
    item.kind                = 'provider'
    item.save
    @accounting_plan.providers << item

    item = AccountingPlanItem.new
    item.third_party_name    = 'Virement'
    item.third_party_account = '0VIR'
    item.conterpart_account  = '9101'
    item.kind                = 'customer'
    item.save
    @accounting_plan.customers << item

    @accounting_plan.save    
  end

  after(:all) do
    DatabaseCleaner.clean
  end

  context "MappingGeneratorController" do    
    it "returns a XML: get_xml" do
      request.accept = "text/xml"
      request.headers["Authorization"] = @token
      request.headers["Content-Type"] = "text/xml"

      data = "<?xml version=\"1.0\"?>
<data>
  <address>
    <name>Test</name>
    <contact>User2 TEST</contact>
    <address_1/>
    <address_2/>
    <zip/>
    <city/>
    <country/>
    <country_code>FR</country_code>
  </address>
  <accounting_plans>
    <wsAccounts>
      <category>1</category>
      <associate>9101</associate>
      <name>Virement</name>
      <number>0VIR</number>
      <vat-account/>
    </wsAccounts>
    <wsAccounts>
      <category>2</category>
      <associate>1234</associate>
      <name>iDocus</name>
      <number>0IDOC</number>
      <vat-account/>
    </wsAccounts>
    <wsAccounts>
      <category>2</category>
      <associate>5678</associate>
      <name>iDocus2</name>
      <number>0IDOC2</number>
      <vat-account/>
    </wsAccounts>
  </accounting_plans>
</data>
"

      expect(@accounting_plan.to_xml.strip).to eq(data.strip)

      get :get_xml, format: :json, params: {:access_token => @token, :user_id => @user}
      expect(response.body).to include(data.strip)
    end

    it 'returns a CSV: get_csv' do
      request.accept = "text/csv"
      request.headers["Authorization"] = @token
      request.headers["Content-Type"] = "text/csv"

      data = 'category,name,number,associate,customer_code
1,Virement,0VIR,9101,IDO%0002
2,iDocus,0IDOC,1234,IDO%0002
2,iDocus2,0IDOC2,5678,IDO%0002'

      expect(@accounting_plan.to_csv).to eq(data.strip)
      get :get_csv, format: :json, params: {:access_token => @token, :user_id => @user}
      expect(response.body).to include(data.strip)
    end

    it 'returns a CSV: get_csv_users_list' do
      request.accept = "text/csv"
      request.headers["Authorization"] = @token
      request.headers["Content-Type"] = "text/csv"

      data = "code,name,company,address_first_name,address_last_name,address_company,address_1,address_2,city,zip,state,country,country_code
IDO%0002,User2 TEST,Test,,,,,,,,,,FR"

      get :get_csv_users_list, format: :json, params: {:access_token => @token}
      expect(response.body).to include(data.strip)
    end
  end  
end

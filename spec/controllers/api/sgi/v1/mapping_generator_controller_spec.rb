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
    it "returns a JSON: get_json" do
      request.headers["ACCEPT"]        = "application/json"
      request.headers["CONTENT_TYPE"]  = "application/json"
      request.headers["HTTP_AUTHORIZATION"] = ActionController::HttpAuthentication::Token.encode_credentials(@token)

      json_content = {
        'address': {
          'name':         'Test',
          'contact':      'User2 TEST',
          'address_1':    nil,
          'address_2':    nil,
          'zip':          nil,
          'city':         nil,
          'country':      nil,
          'country_code': 'FR'
        },

        'accounting_plans': {
          'ws_accounts': [
            { 'category': 1, 'associate': '9101', 'name': 'Virement', 'number': '0VIR', 'vat_account': nil},
            { 'category': 2, 'associate': '1234', 'name': 'iDocus', 'number': '0IDOC', 'vat_account': nil},
            { 'category': 2, 'associate': '5678', 'name': 'iDocus2', 'number': '0IDOC2', 'vat_account': nil}
          ]
        }
      }

      expect(@accounting_plan.create_json_format).to eq(json_content)

      get :get_json, format: :json, params: { :user_code => @user.code }
      expect(JSON.parse(response.body)['data']).to eq(json_content)
    end
  end
end

require 'spec_helper'

describe 'API V1 Authorization' do
  before(:all) do
    @user = FactoryBot.create :user, code: 'TS%0001'
    @user.update_authentication_token

    @admin = FactoryBot.create :admin
    @admin.update_authentication_token
  end

  it 'without access_token should be unauthorized' do
    get '/api/v1/pre_assignments', format: 'json'
    expect(response).not_to be_successful
    expect(response.code.to_i).to eq(401)
  end

  context 'using params' do
    it 'invalid access_token should be unauthorized' do
      get '/api/v1/pre_assignments', format: 'json', access_token: '12345'
      expect(response).not_to be_successful
      expect(response.code.to_i).to eq(401)
    end

    it 'valid access_token should be authorized' do
      get '/api/v1/pre_assignments', format: 'json', access_token: @admin.authentication_token
      expect(response).to be_successful
      expect(response.code.to_i).to eq(200)
    end
  end

  context 'using header' do
    it 'invalid access_token should be unauthorized' do
      headers = {
        'HTTP_AUTHORIZATION' => ActionController::HttpAuthentication::Token.encode_credentials(12345)
      }
      get '/api/v1/pre_assignments', { format: 'json' }, headers
      expect(response).not_to be_successful
      expect(response.code.to_i).to eq(401)
    end

    it 'valid access_token should be authorized' do
      headers = {
        'HTTP_AUTHORIZATION' => ActionController::HttpAuthentication::Token.encode_credentials(@admin.authentication_token)
      }
      get '/api/v1/pre_assignments', { format: 'json' }, headers
      expect(response).to be_successful
      expect(response.code.to_i).to eq(200)
    end
  end

  context 'with valid access_token' do
    it 'visiting pre_assignments #index as customer should be unauthorized' do
      get '/api/v1/pre_assignments', format: 'json', access_token: @user.authentication_token
      expect(response).not_to be_successful
      expect(response.code.to_i).to eq(401)
    end

    it 'visiting pre_assignments #index as operator should be authorized' do
      operator = FactoryBot.create :operator
      operator.update_authentication_token

      get '/api/v1/pre_assignments', format: 'json', access_token: operator.authentication_token
      expect(response).to be_successful
      expect(response.code.to_i).to eq(200)
    end

    it 'visiting pre_assignments #index as admin should be authorized' do
      get '/api/v1/pre_assignments', format: 'json', access_token: @admin.authentication_token
      expect(response).to be_successful
      expect(response.code.to_i).to eq(200)
    end
  end
end

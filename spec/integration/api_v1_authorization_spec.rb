require 'spec_helper'

describe 'API V1 Authorization' do
  before(:all) do
    DatabaseCleaner.start

    @user = FactoryGirl.create :user, code: 'TS%0001'
    @user.update_authentication_token
  end

  after(:all) do
    DatabaseCleaner.clean
  end

  it 'without access_token should be unauthorized' do
    get '/api/v1/operations', format: 'json'
    response.should_not be_successful
    response.code.to_i.should eq(401)
  end

  context 'using params' do
    it 'invalid access_token should be unauthorized' do
      get '/api/v1/operations', format: 'json', access_token: '12345'
      response.should_not be_successful
      response.code.to_i.should eq(401)
    end

    it 'valid access_token should be authorized' do
      get '/api/v1/operations', format: 'json', access_token: @user.authentication_token
      response.should be_successful
      response.code.to_i.should eq(200)
    end
  end

  context 'using header' do
    it 'invalid access_token should be unauthorized' do
      headers = {
        'HTTP_AUTHORIZATION' => ActionController::HttpAuthentication::Token.encode_credentials(12345)
      }
      get '/api/v1/operations', { format: 'json' }, headers
      response.should_not be_successful
      response.code.to_i.should eq(401)
    end

    it 'valid access_token should be authorized' do
      headers = {
        'HTTP_AUTHORIZATION' => ActionController::HttpAuthentication::Token.encode_credentials(@user.authentication_token)
      }
      get '/api/v1/operations', { format: 'json' }, headers
      response.should be_successful
      response.code.to_i.should eq(200)
    end
  end
end

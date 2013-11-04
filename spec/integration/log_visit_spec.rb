require 'spec_helper'

describe 'Logging visit' do
  before(:each) do
    DatabaseCleaner.start
  end

  after(:each) do
    DatabaseCleaner.clean
  end
  
  context 'as visitor' do
    it 'should log successfully homepage visit' do
      visit '/'
      page.current_path.should eq('/')
      log = Log::Visit.first
      log.user.should eq(nil)
      log.path.should eq('/')
    end
  end

  context 'as logged user' do
    login_user

    it 'should log successfully account/documents visit' do
      visit '/account/documents'
      page.current_path.should eq('/account/documents')
      user = User.first
      log = Log::Visit.first
      log.user.should eq(user)
      log.path.should eq('/account/documents')
    end
  end

  context 'as logged admin' do
    login_admin
    
    it 'should not log visit' do
      visit '/account/documents'
      page.current_path.should eq('/account/documents')
      log = Log::Visit.first
      log.should be_nil
    end
  end
end

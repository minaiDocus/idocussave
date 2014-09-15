require 'spec_helper'

describe 'Create event on visit' do
  before(:each) do
    DatabaseCleaner.start
  end

  after(:each) do
    DatabaseCleaner.clean
  end

  context 'as visitor' do
    it 'create page visit event on /users/sign_in' do
      visit '/'
      page.current_path.should eq('/users/sign_in')
      event = Event.first
      expect(event.user).to be_nil
      expect(event.path).to eq('/')
    end
  end

  context 'as an user' do
    login_user

    it 'create page visit event on /account/documents' do
      visit '/account/documents'
      page.current_path.should eq('/account/documents')
      user = User.first
      event = Event.first
      expect(event.user).to eq(user)
      expect(event.path).to eq('/account/documents')
    end
  end

  context 'as an admin' do
    login_admin

    it 'does not create page visit event on /account/documents' do
      visit '/account/documents'
      page.current_path.should eq('/account/documents')
      event = Event.first
      expect(event).to be_nil
    end
  end
end

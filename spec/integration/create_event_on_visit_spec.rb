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
      expect(page.current_path).to eq('/users/sign_in')
      event = Event.first
      expect(event.user).to be_nil
      expect(event.path).to eq('/')
    end
  end

  context 'as an user' do
    it 'create page visit event on /account/documents' do
      @user = FactoryBot.create(:user)
      @user.options = UserOptions.create(user_id: @user.id)
      @user.organization = Organization.create(name: 'TEST', code: 'TS')
      @user.save

      page.driver.post user_session_path,
        user: { email: @user.email, password: @user.password }

      visit '/account/documents'
      expect(page.current_path).to eq('/account/documents')
      user = User.first
      event = Event.first
      expect(event.user).to eq(user)
      expect(event.path).to eq('/account/documents')
    end
  end

  context 'as an admin' do
    it 'does not create page visit event on /account/documents' do
      @user = FactoryBot.create(:admin, code: 'TS%0001')
      @user.organization = Organization.create(name: 'TEST', code: 'TS')
      @user.save

      page.driver.post user_session_path,
        user: { email: @user.email, password: @user.password }

      visit '/account/documents'
      expect(page.current_path).to eq('/account/documents')
      event = Event.first
      expect(event).to be_nil
    end
  end
end

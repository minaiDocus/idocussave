require 'spec_helper'

describe PagesController do
	before(:each) do
    DatabaseCleaner.start
  end

  after(:each) do
    DatabaseCleaner.clean
  end

  describe 'Visiting page About' do
		it 'should be successful' do
			Page.create(title: 'about', label: 'about', tag: 'about')
			get :show, id: 'about'
			response.should be_successful
		end
		
		it 'should raise Mongoid::Errors::DocumentNotFound' do
      expect { get :show, id: 'about' }.to raise_error(Mongoid::Errors::DocumentNotFound)
    end
	end
end

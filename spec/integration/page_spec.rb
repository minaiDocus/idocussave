require 'spec_helper'

describe "Visiting page" do
	
	describe "about" do
		it "should be successful" do
			Page.create(title: 'about', label: 'about', tag: 'about')
			visit '/pages/about'
			page.status_code.should eq(200)
		end
		
		it "should return '404 page not found'" do
      expect { get '/pages/show', :id => 'about'}.to raise_error(Mongoid::Errors::DocumentNotFound)
		end
	end
end

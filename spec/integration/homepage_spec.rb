require 'spec_helper'

describe "Homepage" do
	before(:each) do
		Page.create(title: 'about', label: 'about', tag: 'about')
	end
	
	describe "as visitor" do
		it "should visit successfuly homepage" do
			visit '/'
			page.body.should include("about")
			page.status_code.should eq(200)
		end
		
		it "should be redirected to user's signing" do
			visit '/preview/about'
			page.current_path.should eq('/users/sign_in')
		end
	end
	
	describe "as admin" do
		login_admin
		
		it "should visit successfuly preview" do
			visit '/preview/about'
			page.status_code.should eq(200)
		end
	end
end

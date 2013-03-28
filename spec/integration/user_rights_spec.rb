# -*- encoding : UTF-8 -*-
require 'spec_helper'

describe "user_rights" do
	
	describe "Logged_user" do
		login_user
		
		it "should visit successfuly profile" do
			visit ('/account/profile')
			
			page.status_code.should eq(200)
			page.current_path.should eq('/account/profile')
		end
		
		it "should visit successfuly documents" do
			visit('/account/documents')
		
			page.status_code.should eq(200)
			page.current_path.should eq('/account/documents')
		end
		
		it "should visit successfuly reportings" do
			visit('/account/reporting')
		
			page.status_code.should eq(200)
			page.current_path.should eq('/account/reporting')
		end
	end	

	describe "Logged_admin" do
		login_admin

		it "should visit successfuly admin" do
			visit('/admin')
			page.status_code.should eq(200)
			page.current_path.should eq ('/admin')
		end

		it "should visit successfuly users" do
			visit ('/admin/users')
			page.status_code.should eq(200)
			page.current_path.should eq('/admin/users')
		end

		it "should visit successfuly pages" do
			visit ('/admin/pages')
			page.status_code.should eq(200)
			page.current_path.should eq('/admin/pages')
		end

		it "should visit successfuly new page" do
			visit('/admin/pages/new')
			page.status_code.should eq(200)
			page.current_path.should eq('/admin/pages/new')
		end

		it "should visit successfuly cms images" do
			visit('/admin/cms_images')
			page.status_code.should eq(200)
			page.current_path.should eq('/admin/cms_images')
		end

		it "should visit successfuly products" do
			visit ('/admin/products')
			page.status_code.should eq(200)
			page.current_path.should eq('/admin/products')
		end

		it "should visit successfuly new product" do
			visit('/admin/products/new')
			page.status_code.should eq(200)
			page.current_path.should eq('/admin/products/new')
		end

		it "should visit successfuly new product option" do
			visit('/admin/product_options/new')
			page.status_code.should eq(200)
			page.current_path.should eq('/admin/product_options/new')
		end

		it "should visit successfuly new product option" do
			visit ('/admin/product_groups/new')
			page.status_code.should eq(200)
			page.current_path.should eq('/admin/product_groups/new')
		end
		
		it "should visit successfuly preview" do
			Page.create(title: 'about', label: 'about', tag: 'about', is_for_preview: true)
			
			visit '/preview/about'
			page.status_code.should eq(200)
			page.current_path.should eq('/preview/about')
		end
	end
end

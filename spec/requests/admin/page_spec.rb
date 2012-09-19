# -*- encoding : UTF-8 -*-
require 'spec_helper'

describe "Page" do
	login_admin
	
	before(:each) do
		Page.destroy_all
		FactoryGirl.create(:page, title: 'scan', label: 'scan', tag: 'scan')
	end
	
	it "should successfuly persisted" do
		visit ('/admin/pages/new')
		
		page.current_path.should eq('/admin/pages/new')
		fill_in 'Titre', with: 'multimédia'
		fill_in 'Label', with: 'multimédia'
		fill_in 'Position', with: 2
		fill_in 'Libellé du type de page', with: 'multimédia'
		check 'Afficher dans le pied de page'
		check 'Est visible ?'
		uncheck 'Est visible pour la preview ?'

		click_button('Valider')	
		
		page = Page.where(position: 2).first
		page.title.should eq('multimédia')
		
	end
	
	it "should successfuly updated after editing" do
		visit ('/admin/pages/scan/edit')
		page.current_path.should eq('/admin/pages/scan/edit')
		page.status_code.should eq(200)
		fill_in 'Titre', with: 'ocr'
		click_button('Valider')
		
		page = Page.where(title: 'ocr').first
		page.should_not eq nil
	end
	
	it "should visit successfuly show page" do
		visit '/admin/pages'
		visit '/admin/pages/scan'
		
		page.current_path.should eq '/admin/pages/scan'
		page.status_code.should eq 200
	end
end
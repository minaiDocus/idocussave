# -*- encoding : UTF-8 -*-
require 'spec_helper'

describe "Product" do
	login_admin
	
	before(:each) do
		Product.destroy_all
		FactoryGirl.create(:product, title: 'Multimedia', price_in_cents_wo_vat: 500)
	end
	
	it "should successfully persisted" do
		visit '/admin/products/new'
		
		fill_in 'Titre', with: 'Game'
		fill_in 'Position', with: 1
		fill_in 'Prix', with: 500
		check 'Abonnement'
		uncheck 'Adresse de facturation requise ?'
		fill_in 'Description', with: 'Arcade game'
		fill_in 'Informations d\'entête de page', with: 'Arcade game'
		fill_in 'Informations de pied de page', with: 'Arcade game'	
		click_button 'Valider'	
		
		product = Product.where(title: 'Game')
		product.should be_present		
	end
	
	it "should successfully updated after editing" do
		visit ('/admin/products')
		visit ('/admin/products/multimedia/edit')
		
		fill_in 'Position', with: 2
		fill_in 'Prix', with: 1000
		click_button 'Valider'
		
		product = Product.where(title: 'Multimedia').first
		product.price_in_cents_wo_vat.should eq(1000)
	end
end

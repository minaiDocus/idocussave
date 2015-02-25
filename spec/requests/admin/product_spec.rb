# -*- encoding : UTF-8 -*-
require 'spec_helper'

describe 'Product' do
  login_admin

  before(:each) do
    Product.destroy_all
    FactoryGirl.create(:product, title: 'Multimedia')
  end

  it 'should be persisted' do
    visit '/admin/products/new'

    fill_in 'Titre', with: 'Game'
    fill_in 'Position', with: 1
    click_button 'Valider'

    product = Product.where(title: 'Game').first
    expect(product).to be_present
  end

  it 'should successfully updated after editing' do
    visit ('/admin/products/multimedia/edit')

    fill_in 'Position', with: 2
    click_button 'Valider'

    product = Product.where(title: 'Multimedia', position: 2).first
    expect(product).to be_present
  end
end

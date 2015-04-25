require 'spec_helper'

describe Admin::ProductOptionsController do
  before(:each) do
    ProductOption.destroy_all
    @product_option =  FactoryGirl.create(:product_option, title: 'game', name: 'game')
    @request.env["devise.mapping"] = Devise.mappings[:user]
    user = FactoryGirl.create(:admin)
    sign_in user
  end

  it "GET 'new'" do
    get 'new'
    expect(response).to be_success
  end

  describe "POST 'create'" do
    it "should success" do
      post :create, product_option: { name: 'option', title: 'option', position: 1, price_in_cents_wo_vat: 100 }
      option = ProductOption.where(name: 'option').first
      expect(option).not_to be_nil
    end
  end

  it "GET 'edit'" do
    get :edit, id: @product_option.to_param
    expect(response).to be_success
  end

  describe "POST 'update'" do
    it "should be success" do
      put :update, id: @product_option, product_option: FactoryGirl.attributes_for(:product_option, title: 'pad')
      @product_option.reload
      expect(@product_option.title).to eq ('pad')
    end

    it "should fail" do
      put :update, id: @product_option, product_option: FactoryGirl.attributes_for(:product_option, title: nil)
      @product_option.reload
      expect(@product_option.title).to eq('game')
    end
  end

  it "POST 'destroy'" do
    delete :destroy, id: @product_option
    option = ProductOption.where(name: 'game').first
    expect(option).not_to be_present
  end
end

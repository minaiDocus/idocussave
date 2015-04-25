require 'spec_helper'

describe Admin::ProductsController do
  render_views

  before(:each) do
    Product.destroy_all
    @product = FactoryGirl.create(:product, title: 'game')
    @request.env["devise.mapping"] = Devise.mappings[:user]
    user = FactoryGirl.create(:admin)
    sign_in user
  end

  it "GET 'index'" do
    get 'index'
    expect(assigns(:products)).to eq([@product])
  end

  it "GET 'new'" do
    get 'new'
    expect(response).to be_success
  end

  describe "POST 'create'" do
    it "should success" do
      post :create, product: { title: 'product', position: 1 }
      product = Product.where(title: 'product').first
      expect(product).not_to be_nil
    end
  end

  it "GET 'edit'" do
    get :edit, id: @product.to_param
    expect(response).to be_success
  end

  describe "POST 'update'" do
    it "should be success" do
      put :update, id: @product, product: FactoryGirl.attributes_for(:product, title: 'pad')
      @product.reload
      expect(@product.title).to eq ('pad')
    end

    it "should fail" do
      put :update, id: @product, product: FactoryGirl.attributes_for(:product, title: nil)
      @product.reload
      expect(@product.title).to eq('game')
    end
  end

  it "POST 'destroy'" do
    delete :destroy, id: @product
    product = Product.where(title:'game').first
    expect(product).not_to be_present
  end
end

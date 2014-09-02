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
    response.should be_success
  end

  describe "POST 'create'" do
    it "should success" do
      post :create, product_option: FactoryGirl.attributes_for(:product_option)
      response.should be_success
    end

    it "should fail" do
      post :create, product_option: FactoryGirl.attributes_for(:product_option)
      response.should render_template("admin/product_options")
    end
  end

  it "GET 'edit'" do
    get :edit, id: @product_option.to_param
    response.should be_success
  end

  describe "POST 'update'" do
    it "should be success" do
      put :update, id: @product_option, product_option: FactoryGirl.attributes_for(:product_option, title: 'pad')
      @product_option.reload
      @product_option.title.should eq ('pad')
    end

    it "should fail" do
      put :update, id: @product_option, product_option: FactoryGirl.attributes_for(:product_option, title: nil)
      @product_option.reload
      @product_option.title.should eq('game')
    end
  end

  it "POST 'destroy'" do
    delete :destroy, id: @product_option
    option = ProductOption.where(name: 'game').first
    option.should_not be_present
  end
end

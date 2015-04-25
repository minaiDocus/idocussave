require 'spec_helper'

describe Admin::ProductGroupsController do
  render_views

  before(:each) do
    ProductGroup.destroy_all
    @product_group =  FactoryGirl.create(:product_group, name: 'game')
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
      post :create, product_group: { name: 'group', title: 'group', position: 1 }
      group = ProductGroup.where(name: 'group').first
      expect(group).not_to be_nil
    end
  end

  it "PUT a group" do
    put :update, id: @product_group, product_group: FactoryGirl.attributes_for(:product_group, name: 'premium')
    @product_group.reload
    expect(@product_group.name).to eq ('premium')
  end

  it "does not change @group's attributes" do
    put :update, id: @product_group, product_group: FactoryGirl.attributes_for(:product_group, name: nil)
    @product_group.reload
    expect(@product_group.name).to eq('game')
  end

  it "DELETE a group" do
    delete :destroy, id: @product_group
    group = ProductGroup.where(name: 'game').first
    expect(group).not_to be_present
  end
end

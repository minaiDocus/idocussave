require 'spec_helper'

describe Product do
  before(:each) do
    Product.destroy_all
   
    @product1 = FactoryGirl.create(:product, title: 'Product 1')
    @product2 = FactoryGirl.create(:product, title: 'Product 2')
    @product3 = FactoryGirl.create(:product, title: 'Product 3')
  end
  
  describe '.by_price_ascending' do
    subject(:products) { Product.by_price_ascending}
   
    it { subject[0].should eq(@product1) }
    it { subject[1].should eq(@product2) }
    it { subject[2].should eq(@product3) }
  end
  
  
  describe ".by_position" do
    subject (:products) { Product.by_position }
    
    it { subject[0].should eq(@product1) }
    it { subject[1].should eq(@product2) }
    it { subject[2].should eq(@product3) }
  end
    
  describe ".find_by_slug" do
    subject(:product) { Product.find_by_slug('product-1') } 
    
    it { subject.should eq(@product1) }
  end

  it "#price_in_cents_w_vat" do
    @product1.price_in_cents_wo_vat = 1000
    @product1.price_in_cents_w_vat.should eq(1200)
  end
end

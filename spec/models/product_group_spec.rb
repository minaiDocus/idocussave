require 'spec_helper'

describe ProductGroup do
  before(:each) do
    ProductGroup.destroy_all
    
    @product_group1 = ProductGroup.create(position: 3, title: 'groupe1', name: 'groupe1')
    @product_group2 = ProductGroup.create(position: 2, title: 'groupe2', name: 'groupe2')
    @product_group3 = ProductGroup.create(position: 1, title: 'groupe3', name: 'groupe3')
  end
  
  describe ".by_position" do
    subject(:product_groups) { ProductGroup.by_position }
    
    it { subject[0].should eq(@product_group3) }
    it { subject[1].should eq(@product_group2) }
    it { subject[2].should eq(@product_group1) }
  end
  
  describe ".find_by_slug" do
    subject(:product_group) { ProductGroup.find_by_slug('groupe2') }
    
    it { subject.should eq(@product_group2) }
  end
end

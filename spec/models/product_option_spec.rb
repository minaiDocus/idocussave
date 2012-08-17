require 'spec_helper'

describe ProductOption do
  before(:each) do 
    ProductOption.destroy_all
    
    @product_option1 = ProductOption.create(position: 2, title: 'option1', price_in_cents_wo_vat: 300)
    @product_option2 = ProductOption.create(position: 1, title: 'option2', price_in_cents_wo_vat: 400)
    @product_option3 = ProductOption.create(position: 3, title: 'option3', price_in_cents_wo_vat: 200)
    @product_option4 = ProductOption.create(position: 4, title: 'option4', price_in_cents_wo_vat: 100)
    
    @product_group1 = ProductGroup.create(position: 2, title: 'groupe1', name: 'groupe1')
    @product_group2 = ProductGroup.create(position: 1, title: 'groupe2', name: 'groupe2')
    
    @product_group1.product_options << @product_option1
    @product_group1.product_options << @product_option2
    @product_group1.save
    
    @product_group2.product_options << @product_option4
    @product_group2.product_options << @product_option3
    @product_group2.save
  end
  
  describe ".by_position" do
    subject(:product_options) { ProductOption.by_position }
   
    it { subject[0].should eq(@product_option2) }
    it { subject[1].should eq(@product_option1) }
    it { subject[2].should eq(@product_option3) }
  end
  
  describe ".find_by_slug" do
    subject(:product_option) { ProductOption.find_by_slug('option3') }
    
    it { subject.should eq(@product_option3) }
  end
  
  describe ".by_group" do
    subject(:product_options) { ProductOption.by_group }
    
    it { subject[0].should eq(@product_option1) }
    it { subject[1].should eq(@product_option2) }
    it { subject[2].should eq(@product_option4) }
    it { subject[3].should eq(@product_option3) }

  end
  
  describe "#price_in_cents_w_vat" do
    subject(:product_option) { @product_option1.price_in_cents_w_vat }
    
    it { subject.should eq(358.8) }
  end
  
  describe "#group_title" do
    subject(:product_option) { @product_option1.group_title }
    
    it { subject.should eq('groupe1') }
  end
  
  describe "#group_position" do
    subject(:product_option) { @product_option1.group_position }
    
    it { subject.should eq(2) }
  end
end

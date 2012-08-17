require 'spec_helper'

describe Product do
  before(:each) do
    ProductOption.destroy_all
    ProductGroup.destroy_all
    Product.destroy_all
   
    @product = FactoryGirl.create(:product, title: 'product1')
    
    @product_group1 = ProductGroup.create(position: 1, title: 'productgroup1', name: 'productgroup1')
    @product_group2 = ProductGroup.create(position: 2, title: 'productgroup2', name: 'productgroup2')
    
    @product_option1 = FactoryGirl.create(:product_option, position: 1, title: 'productoption1')
    @product_option2 = FactoryGirl.create(:product_option, position: 2, title: 'productoption2')
    @product_option3 = FactoryGirl.create(:product_option, position: 3, title: 'productoption3')
    @product_option4 = FactoryGirl.create(:product_option, position: 4, title: 'productoption4')  

    @product_group1.product_options << @product_option1
    @product_group1.product_options << @product_option2
    @product_group1.save
    
    @product_group2.product_options << @product_option3
    @product_group2.product_options << @product_option4
    @product_group2.save
    
    @product.product_groups << @product_group1
    @product.product_groups << @product_group2
    @product.save
    
    @group_count = Product.first.product_groups.count
   
    @option_count1 = Product.first.product_groups.first.product_options.count    
    @option_count2 = Product.first.product_groups.last.product_options.count     
    
    @option1 = Product.first.product_groups.first.product_options.all
    @option2 = Product.first.product_groups.last.product_options.all
 
    @product_title = @product_option1.product_group.product.title
  end
  
  describe ".group count" do
    subject(:nb) { @group_count }
    
    it { subject.should eq(2) }
  end
  
  describe ".option count per group" do
   subject (:nb) { @option_count1 and @option_count2 }
    
   it { subject.should eq(2) }
    
  end

  describe ".[0-1] = [1-2 options] " do
    subject (:product_options) { @option1 }
    
    it { subject.should include(@product_option1) }
    it { subject.should include(@product_option2) }
  end
  
  describe ".[0-1] = [3-4 options]" do
    subject (:product_options) { @option2 }
   
    it { subject.should include(@product_option3) }
    it { subject.should include(@product_option4) }
  end
  
  describe ".option -> group -> product title" do
    subject(:product) { @product_title }
    
    it { subject.should eq(@product.title) }
  end

end

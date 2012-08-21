require 'spec_helper'

describe Product do
  before(:each) do
    Product.destroy_all
    ProductGroup.destroy_all
    ProductOption.destroy_all

    @product = FactoryGirl.create(:product, title: 'Game console')
    
    @group1 = ProductGroup.create(position: 1, title: 'Pad', name: 'pad')
    @group2 = ProductGroup.create(position: 2, title: 'Game', name: 'game')
    
    @option1 = FactoryGirl.create(:product_option, title: '1 pad')
    @option2 = FactoryGirl.create(:product_option, title: '2 pads')
    @option3 = FactoryGirl.create(:product_option, title: '3 games')
    @option4 = FactoryGirl.create(:product_option, title: '5 games')

    @group1.product_options << @option1
    @group1.product_options << @option2
    @group1.save
    
    @group2.product_options << @option3
    @group2.product_options << @option4
    @group2.save
    
    @product.product_groups << @group1
    @product.product_groups << @group2
    @product.save
  end
  
  context "Groups" do
    it "count should equal 2" do
      @product.product_groups.count.should eq(2)
    end

    describe "first group options" do
      subject(:options_title) { @group1.product_options.distinct(:title) }

      it { subject.should include(@option1.title) }
      it { subject.should include(@option2.title) }
    end

    describe "last group options" do
      subject(:options_title) { @group2.product_options.distinct(:title) }

      it { subject.should include(@option3.title) }
      it { subject.should include(@option4.title) }
    end

    context "Options" do
      it "count should equal 4" do
        total = 0
        @product.product_groups.each { |g| total += g.product_options.count }
        total.should eq(4)
      end
    end
  end
  
  it "title should equal 'Game console'" do
    @option1.product_group.product.title.should eq(@product.title)
  end
end

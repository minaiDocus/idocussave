require 'spec_helper'

describe Product do
  before(:each) do
    Product.destroy_all

    @product1 = FactoryGirl.create(:product, title: 'Product 1')
    @product2 = FactoryGirl.create(:product, title: 'Product 2')
    @product3 = FactoryGirl.create(:product, title: 'Product 3')
  end

  describe ".by_position" do
    subject (:products) { Product.by_position }

    it { expect(subject[0]).to eq(@product1) }
    it { expect(subject[1]).to eq(@product2) }
    it { expect(subject[2]).to eq(@product3) }
  end

  describe ".find_by_slug!" do
    subject(:product) { Product.find_by_slug!('product-1') }

    it { expect(subject).to eq(@product1) }
  end
end

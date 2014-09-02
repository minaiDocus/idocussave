require 'spec_helper'

describe ProductOption do
  before(:each) do
    ProductGroup.destroy_all
    ProductOption.destroy_all

    @option1 = ProductOption.create(position: 2, title: 'option1', name: 'option1', price_in_cents_wo_vat: 300)
    @option2 = ProductOption.create(position: 1, title: 'option2', name: 'option2',  price_in_cents_wo_vat: 400)
    @option3 = ProductOption.create(position: 3, title: 'option3', name: 'option3',  price_in_cents_wo_vat: 200)
    @option4 = ProductOption.create(position: 4, title: 'option4', name: 'option4',  price_in_cents_wo_vat: 100)

    @group1 = ProductGroup.create(position: 2, title: 'groupe1', name: 'groupe1')
    @group2 = ProductGroup.create(position: 1, title: 'groupe2', name: 'groupe2')

    @group1.product_options << @option1
    @group1.product_options << @option2
    @group1.save

    @group2.product_options << @option4
    @group2.product_options << @option3
    @group2.save
  end

  describe ".by_position" do
    subject(:options) { ProductOption.by_position.map { |option| option.title } }

    it { subject[0].should eq(@option2.title) }
    it { subject[1].should eq(@option1.title) }
    it { subject[2].should eq(@option3.title) }
  end

  describe ".find_by_slug" do
    subject(:product_option) { ProductOption.find_by_slug('option3').title }

    it { subject.should eq(@option3.title) }
  end

  describe ".by_group" do
    subject(:options) { ProductOption.by_group.map { |option| option.product_group.title } }

    it { subject[0].should eq(@group1.title) }
    it { subject[1].should eq(@group1.title) }
    it { subject[2].should eq(@group2.title) }
    it { subject[3].should eq(@group2.title) }
  end

  describe "#price_in_cents_w_vat should equal 360" do
    subject(:option) { @option1.price_in_cents_w_vat }

    it { subject.should eq(360) }
  end

  describe "#group title should equal 'groupe1' " do
    subject(:option) { @option1.group_title }

    it { subject.should eq('groupe1') }
  end

  describe "#group_position" do
    subject(:option) { @option1.group_position }

    it { subject.should eq(2) }
  end
end

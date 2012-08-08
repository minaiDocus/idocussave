require 'spec_helper'

describe Page::Image do
  describe 'Specifications' do
    # validation
    it { should validate_presence_of( :name)}

    # fields
    it { should have_field( :is_invisible).of_type(Boolean).with_default_value_of(false) }
    it { should have_field( :position).of_type(Integer).with_default_value_of(1) }

    # association
    it { should be_embedded_in( :page).of_type(Page).as_inverse_of(:images) }
  end

  describe 'Features' do
    before(:each) do
      Page.destroy_all
      @page = FactoryGirl.build(:page)
      @image1 = FactoryGirl.build(Page::Image, name: 'image1', position: 20)
      @image2 = FactoryGirl.build(Page::Image, name: 'image2', position: 10)
      @image3 = FactoryGirl.build(Page::Image, name: 'image3', position: 10)
      @page.images << @image1
      @page.images << @image2
      @page.images << @image3
      @page.save
    end

    describe '.by_position' do
      subject(:images) { @page.images.by_position.entries }

      it { subject[0].should eq(@image2) }
      it { subject[1].should eq(@image3) }
      it { subject[2].should eq(@image1) }
    end
  end

end
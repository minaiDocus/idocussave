require 'spec_helper'

describe Page::Content do
  describe 'specifications' do
    # validations
    it { should validate_presence_of(:title)}
    it { should validate_presence_of(:text) }
    it { should validate_presence_of(:tag) }

    # fields
    it { should have_field(:model).of_type(Integer).with_default_value_of(0) }
    it { should have_field(:position).of_type(Integer).with_default_value_of(1) }
    it { should have_field(:is_invisible).of_type(Boolean).with_default_value_of(false) }
    it { should have_field(:tag).of_type(String).with_default_value_of('info') }

    # association
    it { should be_embedded_in(:page).of_type(Page).as_inverse_of(:contents) }
  end

  describe 'features' do
    before(:each) do
      Page.destroy_all
      @page = FactoryGirl.build(:page)
      @content1 = FactoryGirl.build(Page::Content, position: 20)
      @content2 = FactoryGirl.build(Page::Content, position: 10, is_invisible: true)
      @content3 = FactoryGirl.build(Page::Content, position: 10)
      @page.contents << @content1
      @page.contents << @content2
      @page.contents << @content3
      @page.save
    end

    describe '.by_position' do
      subject(:contents) { @page.contents.by_position.entries }

      it { subject[0].should eq(@content2) }
      it { subject[1].should eq(@content3) }
      it { subject[2].should eq(@content1) }
    end

    describe '.distinct_tag' do
      subject(:tags) { @page.contents.distinct_tag }

      it { should include(@content1.tag) }
      it { should include(@content2.tag) }
      it { should include(@content3.tag) }
    end

    describe '.visible' do
      subject(:tags) { @page.contents.visible.entries }

      it { should include(@content1) }
      it { should_not include(@content2) }
      it { should include(@content3) }
    end

    describe '.invisible' do
      subject(:tags) { @page.contents.invisible.entries }

      it { should_not include(@content1) }
      it { should include(@content2) }
      it { should_not include(@content3) }
    end
  end
end

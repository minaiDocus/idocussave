require 'spec_helper'

describe Page do
  describe "specifications" do
    # validations
    it { should validate_presence_of(:title)}
    it { should validate_presence_of(:label) }
    it { should validate_presence_of(:tag) }

    # fields
    it { should have_field(:is_footer).of_type(Boolean).with_default_value_of(false) }
    it { should have_field(:is_invisible).of_type(Boolean).with_default_value_of(false) }
    it { should have_field(:is_for_preview).of_type(Boolean).with_default_value_of(false) }

    # associations
    it { should embed_many(:images) }
    it { should embed_many(:contents) }
    it { should embed_many(:page_contents) }
  end

  describe "features" do
    context "simple" do
      before(:each) do
        Page.destroy_all
        @page = FactoryGirl.create(:page)
        @image = FactoryGirl.build(Page::Image, position: 20)
        @image2 = FactoryGirl.build(Page::Image, position: 10)
      end

      it ".homepage" do
        @page.update_attribute(:tag, 'Homepage')
        Page.homepage.should eq(@page)
      end

      it ".by_position" do
        Page.destroy_all
        page1 = FactoryGirl.create(:page, position: 20)
        page2 = FactoryGirl.create(:page, position: 10)
        pages = Page.all.by_position.entries
        pages.first.should eq(page2)
        pages.last.should eq(page1)
      end

      it "#image" do
        @page.images << @image
        @page.images << @image2
        @page.image.should eq(@image2)
      end
    end

    context "complex" do
      before(:each) do
        Page.destroy_all
        @homepage = FactoryGirl.create(:page, tag: 'Homepage')
        @page1 = FactoryGirl.create(:page, tag: 'Offres', position: 30)
        @page2 = FactoryGirl.create(:page, tag: 'Offres', position: 40)
        @page3 = FactoryGirl.create(:page, tag: 'iDocus ?', position: 10)
        @page4 = FactoryGirl.create(:page, tag: 'iDocus ?', position: 20)
      end

      describe ".all_types" do
        subject(:types) { Page.all_types }

        it { should_not include(@homepage.tag) }
        it { should include(@page1.tag) }
        it { should include(@page3.tag) }
      end

      describe ".all_first_pages" do
        subject(:pages_by_type) { Page.all_first_pages.entries }

        it { should_not include(@homepage) }
        it { subject.first.should eq(@page3) }
        it { subject.last.should eq(@page1) }
      end
    end
  end
end

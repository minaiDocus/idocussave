require 'spec_helper'

describe Division do
  before(:all) do
    User.destroy_all
    Pack.destroy_all

    @user = FactoryGirl.create(:user)
    @pack = FactoryGirl.create(:pack)

    @user.own_packs << @pack
    @pack.owner = @user

    basename = "TS0001_TS_#{Time.now.strftime('%Y%m')}"
    @division1 = @pack.divisions.build(is_an_upload: true,  start: 1,  end: 5,  level: 1, name: basename + "_001")
    @division2 = @pack.divisions.build(is_an_upload: false, start: 6,  end: 7,  level: 1, name: basename + "_002")
    @division3 = @pack.divisions.build(is_an_upload: true,  start: 1,  end: 5,  level: 0, name: basename + "_001")
    @division4 = @pack.divisions.build(is_an_upload: false, start: 6,  end: 7,  level: 0, name: basename + "_002")
    
    @pack.divisions << @division1
    @pack.divisions << @division2
    @pack.divisions << @division3
    @pack.divisions << @division4
    
    @pack.save
    
    @division2.created_at = Time.now + 2.month
    @division4.created_at = Time.now + 2.month
    
    @pack.save
  end
    
  context 'scopes' do
    describe "should return uploaded Division" do
      subject(:divisions) { @pack.divisions.uploaded.map { |division| division.name } }

      it { should include(@division1.name) }
      it { should include(@division3.name) }
    end

    describe "should return scanned Divison" do
      subject(:divisions) { @pack.divisions.scanned.map { |division| division.name } }

      it { should include(@division2.name) }
      it { should include(@division4.name) }
    end

    describe "should return sheets Division" do
      subject(:divisions) { @pack.divisions.sheets.map { |division| division.name } }

      it { should include (@division3.name) }
      it { should include (@division4.name) }
    end

    describe "should return pieces Division" do
      subject(:divisions) { @pack.divisions.pieces.map { |division| division.name } }

      it { should include (@division1.name) }
      it { should include (@division2.name) }
    end

    it ".of_month should return divisions in the month " do
      @pack.divisions.of_month(Time.now).map { |division| division.name }.should include(@division1.name)
      @pack.divisions.of_month(Time.now).map { |division| division.name }.should include(@division3.name)
      @pack.divisions.of_month(Time.now + 2.month).map { |division| division.name }.should include(@division2.name)
      @pack.divisions.of_month(Time.now + 2.month).map { |division| division.name }.should include(@division4.name)
    end
  end
  
  describe ".last" do
    subject(:divisions) { @pack.divisions.last.name }
    
    it { subject.should eq(@division4.name) }
  end
  
  describe ".pages_count" do
    subject(:pages) { @pack.divisions[0].pages_count }
    
    it { should eq(5) }
  end
end

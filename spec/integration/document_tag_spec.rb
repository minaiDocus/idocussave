require 'spec_helper'

describe DocumentTag do
  before(:each) do
    @filepath = "#{Rails.root}/tmp/TS0001_TS_#{Time.now.strftime('%Y%m')}_001.pdf"
    @file = Prawn::Document.generate(@filepath) do |pdf|
      pdf.text "Test file."
    end
  end

  after(:each) do
    system "rm #{Rails.root}/tmp/*.pdf"
  end
	
	it "should have name" do
		user = FactoryGirl.create(:user)
    pack = Pack.create(name: "TS0001 TS #{Time.now.strftime('%Y%m')} all", owner_id: user.id)
		pack.users << user
    user.packs << pack
		user.save
		pack.save
		
		document = Document.new
		document.content = open @filepath
		document.pack = pack
		document.save
	
		pack.document_tags.first.name.should eq(" ts0001 ts #{Time.now.strftime('%Y%m')} all")
	end
end

require 'spec_helper'

describe "get_documents" do
  before(:each) do
    @user = FactoryGirl.create(:user, code: "TS0001")
    @user2 = FactoryGirl.create(:user, code: "TS0002")
    @user.share_with << @user2
    @user.save
    @user2.save
    @period = Time.now.strftime("%Y%m")
    @journal = "TS"
    @basename = [@user.code,@journal,@period].join(' ')
    @name = @basename + ' all'
    @extensions = ['.pdf','.PDF']
    5.times do |i|
      num = ("_%0.3d" % (i+1))
      name = @basename.gsub(' ','_') + num
      up = (i%2 == 0) ? 1 : 0
      filepath = File.join([Pack::FETCHING_PATH,"#{name}#{@extensions[up]}"])
      Prawn::Document.generate(filepath) do |pdf|
        pdf.text "Page 1"
        pdf.start_new_page
        pdf.text "Page 2"
      end
    end
    Pack.get_documents
  end

  after(:each) do
    system "rm /tmp/TS0001_TS*"
    system "rm -r " + File.join([Pack::FETCHING_PATH,"*all"])
  end

  describe "once" do
    it "should be integrated successfully" do
      pack = Pack.find_by_name(@name)
      ss = @user.scan_subscriptions.last
      period = ss.periods.first
      period.documents.count.should eq(1)
      sd = period.documents.first
      sd.pieces.should eq(5)
      sd.sheets.should eq(5)
      sd.pages.should eq(10)
      sd.uploaded_pieces.should eq(0)
      sd.uploaded_sheets.should eq(0)
      sd.uploaded_pages.should eq(0)
      pack.pieces_info.count.should eq(5)
      pack.sheets_info.count.should eq(5)
      pack.pages.count.should eq(10)
      pack.original_document.should eq(pack.documents.originals.first)
      pack.historic.should eq([{date: pack.pages.first.created_at, uploaded: 0, scanned: 10 }])
      period.delivery.state.should eq("delivered")
      pack.scan_documents.count.should eq(1)
    end
  end

  describe "twice" do
    it "should be integrated successfully" do
      5.times do |i|
        num = ("_%0.3d" % (i+1))
        name = @basename.gsub(' ','_') + num
        up = (i%2 == 0) ? 1 : 0
        filepath = File.join([Pack::FETCHING_PATH,"#{name}#{@extensions[up]}"])
        Prawn::Document.generate(filepath) do |pdf|
          pdf.text "Page 1"
          pdf.start_new_page
          pdf.text "Page 2"
        end
      end
      Pack.get_documents
      pack = Pack.find_by_name(@name)
      ss = @user.scan_subscriptions.last
      period = ss.periods.first
      period.documents.count.should eq(1)
      sd = period.documents.first
      sd.pieces.should eq(10)
      sd.sheets.should eq(10)
      sd.pages.should eq(20)
      sd.uploaded_pieces.should eq(0)
      sd.uploaded_sheets.should eq(0)
      sd.uploaded_pages.should eq(0)
      pack.pieces_info.count.should eq(10)
      pack.sheets_info.count.should eq(10)
      pack.pages.count.should eq(20)
      pack.original_document.should eq(pack.documents.originals.first)
      pack.historic.should eq([{date: pack.pages.first.created_at, uploaded: 0, scanned: 20 }])
      period.delivery.state.should eq("delivered")
      pack.scan_documents.count.should eq(1)
    end
  end

  it "should have 5 pieces" do
    pack = Pack.find_by_name(@name)
    pack.pieces.count.should eq(5)
    pack.pieces.each do |piece|
      File.exist?(piece.content.path).should be_true
    end
  end

  it "should share documents automatically" do
    pack = Pack.find_by_name(@name)
    pack.users.should include(@user)
    pack.users.should include(@user2)
  end
end

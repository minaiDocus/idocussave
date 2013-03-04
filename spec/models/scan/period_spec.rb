# -*- encoding : UTF-8 -*-
require 'spec_helper'

describe Scan::Period do
  it "create one period" do
    period = Scan::Period.new
    period.should be_valid
    period.save
    period.should be_persisted
  end

  describe "should return right values" do
    subject(:period) {
      period = Scan::Period.new

      period.max_sheets_authorized = 8
      period.unit_price_of_excess_sheet = 12

      period.max_upload_pages_authorized = 15
      period.quantity_of_a_lot_of_upload = 10
      period.price_of_a_lot_of_upload = 50

      period.max_preseizure_pieces_authorized = 5
      period.unit_price_of_excess_preseizure = 12

      period.max_expense_pieces_authorized = 5
      period.unit_price_of_excess_expense = 12

      period.pieces = 20
      period.sheets = 20
      period.pages = 40
      period.uploaded_pieces = 11
      period.uploaded_sheets = 11
      period.uploaded_pages = 22

      period.excess_preseizure_pieces = 5
      period.excess_expense_pieces = 5

      period.stub(:get_preseizure_pieces){ 10 }
      period.stub(:get_expense_pieces){ 10 }

      period
    }

    it { subject.excess_sheets.should eq(1) }
    it { subject.excess_uploaded_pages.should eq(7) }
    it { subject.get_excess_preseizure_pieces.should eq(5) }
    it { subject.get_excess_expense_pieces.should eq(5) }

    it { subject.price_in_cents_of_excess_sheets.should eq(12) }
    it { subject.price_in_cents_of_excess_uploaded_pages.should eq(50) }
    it { subject.price_in_cents_of_excess_preseizures.should eq(60) }
    it { subject.price_in_cents_of_excess_preseizures.should eq(60) }

    it { subject.price_in_cents_of_total_excess.should eq(182) }
  end
end

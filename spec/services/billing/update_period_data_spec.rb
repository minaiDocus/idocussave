# -*- encoding : UTF-8 -*-
require 'spec_helper'

describe Billing::UpdatePeriodData do
  it 'have default values' do
    period = Period.create(start_date: Date.today)

    Billing::UpdatePeriodData.new(period).execute

    expect(period.pieces).to eq 0
    expect(period.pages).to eq 0
    expect(period.scanned_pieces).to eq 0
    expect(period.scanned_sheets).to eq 0
    expect(period.scanned_pages).to eq 0
    expect(period.dematbox_scanned_pieces).to eq 0
    expect(period.dematbox_scanned_pages).to eq 0
    expect(period.uploaded_pieces).to eq 0
    expect(period.uploaded_pages).to eq 0
    expect(period.retrieved_pieces).to eq 0
    expect(period.retrieved_pages).to eq 0
    expect(period.paperclips).to eq 0
    expect(period.oversized).to eq 0
    expect(period.preseizure_pieces).to eq 0
    expect(period.expense_pieces).to eq 0
    expect(period.documents_name_tags).to eq []
    expect(period.delivery).to be_wait
  end

  it 'set values' do
    user = FactoryBot.create(:user, code: 'TS%0001')
    organization = FactoryBot.create(:organization, code: 'TS')
    period    = Period.create(start_date: Date.today)
    document  = PeriodDocument.create(name: 'TS%0001 J1 201501 all', user: user)
    document.pieces = 10
    document.pages = 10
    document.scanned_pieces = 10
    document.scanned_sheets = 10
    document.scanned_pages = 10
    document.dematbox_scanned_pieces = 10
    document.dematbox_scanned_pages = 10
    document.uploaded_pieces = 10
    document.uploaded_pages = 10
    document.retrieved_pieces = 10
    document.retrieved_pages = 10
    document.paperclips = 10
    document.oversized = 10
    period.documents << document
    report     = Pack::Report.create(name: document.name, user: user, organization: organization)
    report.document = document
    report.save
    pack        = FactoryBot.create :pack, owner: user, organization: organization , name: (report.name + ' all')
    piece       = FactoryBot.create :piece, pack: pack, user: user, organization: organization, name: (report.name + ' 002')
    preseizure  = Pack::Report::Preseizure.create(piece_id: 1, user: user, organization: organization)
    report.preseizures << preseizure
    preseizure2 = Pack::Report::Preseizure.create(piece_id: 1, user: user, organization: organization)
    report.preseizures << preseizure2
    expense     = Pack::Report::Expense.create(piece: piece, user: user, organization: organization)
    report.expenses << expense
    document2 = PeriodDocument.create(name: 'TS%0001 J2 201501 all', user: user)
    document2.pieces = 5
    document2.pages = 5
    document2.scanned_pieces = 5
    document2.scanned_sheets = 5
    document2.scanned_pages = 5
    document2.dematbox_scanned_pieces = 5
    document2.dematbox_scanned_pages = 5
    document2.uploaded_pieces = 5
    document2.uploaded_pages = 5
    document2.retrieved_pieces = 5
    document2.retrieved_pages = 5
    document2.paperclips = 5
    document2.oversized = 5
    period.documents << document2

    Billing::UpdatePeriodData.new(period).execute

    expect(document.report.preseizures).to be_present
    expect(period.pieces).to eq 15
    expect(period.pages).to eq 15
    expect(period.scanned_pieces).to eq 15
    expect(period.scanned_sheets).to eq 15
    expect(period.scanned_pages).to eq 15
    expect(period.dematbox_scanned_pieces).to eq 15
    expect(period.dematbox_scanned_pages).to eq 15
    expect(period.uploaded_pieces).to eq 15
    expect(period.uploaded_pages).to eq 15
    expect(period.retrieved_pieces).to eq 15
    expect(period.retrieved_pages).to eq 15
    expect(period.paperclips).to eq 15
    expect(period.oversized).to eq 15
    expect(period.preseizure_pieces).to eq 2
    expect(period.expense_pieces).to eq 1
    expect(period.documents_name_tags).to eq(["b_J1 y_2015 m_1", "b_J2 y_2015 m_1"])
    expect(period.delivery_state).to eq 'delivered'
  end

  describe '#documents_name_tags' do
    context 'for monthly' do
      it "returns ['b_J1 y_2015 m_1']" do
        period = Period.create(duration: 1, start_date: Date.today)
        period.documents.create(name: 'TS%0001 J1 201501 all')

        Billing::UpdatePeriodData.new(period).execute

        expect(period.documents_name_tags).to eq(['b_J1 y_2015 m_1'])
      end
    end

    context 'for quarterly' do
      it "returns ['b_J1 y_2015 t_1']" do
        period = Period.create(duration: 3, start_date: Date.today)
        period.documents.create(name: 'TS%0001 J1 2015T1 all')

        Billing::UpdatePeriodData.new(period).execute

        expect(period.documents_name_tags).to eq(['b_J1 y_2015 t_1'])
      end
    end

    context 'for yearly' do
      it "returns ['b_J1 y_2015']" do
        period = Period.create(duration: 12, start_date: Date.today)
        period.documents.create(name: 'TS%0001 J1 2015T1 all')

        Billing::UpdatePeriodData.new(period).execute

        expect(period.documents_name_tags).to eq(['b_J1 y_2015'])
      end
    end
  end
end

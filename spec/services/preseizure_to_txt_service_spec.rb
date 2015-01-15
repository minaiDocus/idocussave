# -*- encoding : UTF-8 -*-
require 'spec_helper'

describe PreseizureToTxtService do
  before(:all) do
    user = FactoryGirl.create :user,  code: 'TS%0001'
    journal = AccountBookType.create(name: 'AC', description: 'Achats')
    user.account_book_types << journal
    report = Pack::Report.new
    report.name = 'TS%0001 AC 201501'
    report.save
    @preseizure = Pack::Report::Preseizure.new
    @preseizure.date = Time.local(2015,1,13)
    @preseizure.name = 'TS%0001 AC 201501'
    @preseizure.third_party = 'TIERS'
    @preseizure.observation = 'abcdefghijk'
    @preseizure.user = user
    @preseizure.save
    report.preseizures << @preseizure

    account = Pack::Report::Preseizure::Account.new
    account.type = 1
    account.number = "1TES"
    account.save
    @preseizure.accounts << account
    entry = Pack::Report::Preseizure::Entry.new
    entry.type = 2
    entry.amount = 24.0
    entry.number = '1'
    entry.save
    account.entries << entry
    @preseizure.entries << entry

    account = Pack::Report::Preseizure::Account.new
    account.type = 2
    account.number = "2TES"
    account.save
    @preseizure.accounts << account
    entry = Pack::Report::Preseizure::Entry.new
    entry.type = 1
    entry.amount = 20.0
    entry.number = '2'
    entry.save
    account.entries << entry
    @preseizure.entries << entry

    account = Pack::Report::Preseizure::Account.new
    account.type = 3
    account.number = "3TES"
    account.save
    @preseizure.accounts << account
    entry = Pack::Report::Preseizure::Entry.new
    entry.type = 1
    entry.amount = 4.0
    entry.number = '3'
    entry.save
    account.entries << entry
    @preseizure.entries << entry

    pack = Pack.new
    pack.owner = user
    pack.name = report.name + ' all'
    pack.save
    piece = Pack::Piece.new
    piece.pack = pack
    piece.name = report.name + ' 001'
    piece.origin = 'upload'
    piece.save
    @preseizure.piece = piece
    @preseizure.save
  end

  it 'should match' do
    result = PreseizureToTxtService.new(@preseizure).execute
    lines = result.split("\n")
    expect(lines.size).to eq 3
    expect(lines[0]).to eq 'M1TES    AC000130115 TIERS. abcdefghijk  C+000000002400                                                    EUR                                                                       1.pdf                                                                      '
    expect(lines[1]).to eq 'M2TES    AC000130115 TIERS. abcdefghijk  D+000000002000                                                    EUR                                                                       1.pdf                                                                      '
    expect(lines[2]).to eq 'M3TES    AC000130115 TIERS. abcdefghijk  D+000000000400                                                    EUR                                                                       1.pdf                                                                      '
  end

  it 'should match without label' do
    @preseizure.observation = ''
    @preseizure.third_party = ''
    result = PreseizureToTxtService.new(@preseizure).execute
    lines = result.split("\n")
    expect(lines.size).to eq 3
    expect(lines[0]).to eq 'M1TES    AC000130115                     C+000000002400                                                    EUR                                                                       1.pdf                                                                      '
    expect(lines[1]).to eq 'M2TES    AC000130115                     D+000000002000                                                    EUR                                                                       1.pdf                                                                      '
    expect(lines[2]).to eq 'M3TES    AC000130115                     D+000000000400                                                    EUR                                                                       1.pdf                                                                      '
  end

  it 'should have two lines each that should match' do
    @preseizure.observation = '012345678910111213141516171819202122'
    @preseizure.third_party = 'TIERS'
    lines = PreseizureToTxtService.new(@preseizure).execute.split("\n")
    expect(lines.size).to eq 6
    expect(lines[0]).to eq 'M1TES    AC000130115 TIERS. 0123456789101C+000000002400                                                    EUR      TIERS. 01234567891011121314151                                   1.pdf                                                                      '
    expect(lines[1]).to eq 'M1TES    AC000130115 6171819202122                 0000                                                    EUR                                                                       1.pdf                                                                      '
    expect(lines[2]).to eq 'M2TES    AC000130115 TIERS. 0123456789101D+000000002000                                                    EUR      TIERS. 01234567891011121314151                                   1.pdf                                                                      '
    expect(lines[3]).to eq 'M2TES    AC000130115 6171819202122                 0000                                                    EUR                                                                       1.pdf                                                                      '
    expect(lines[4]).to eq 'M3TES    AC000130115 TIERS. 0123456789101D+000000000400                                                    EUR      TIERS. 01234567891011121314151                                   1.pdf                                                                      '
    expect(lines[5]).to eq 'M3TES    AC000130115 6171819202122                 0000                                                    EUR                                                                       1.pdf                                                                      '
  end
end

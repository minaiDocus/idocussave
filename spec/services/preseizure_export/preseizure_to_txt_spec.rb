# -*- encoding : UTF-8 -*-
require 'spec_helper'

require_dependency 'pack/report/preseizure/account'

describe PreseizureExport::PreseizureToTxt do
  before(:all) do
    organization        = FactoryBot.create(:organization, code: 'IDO')
    user                = FactoryBot.create :user,  code: 'IDO%001', organization: organization
    journal             = AccountBookType.create(name: 'AC', description: 'Achats')
    user.options        = UserOptions.create(user_id: user.id, is_preassignment_authorized: true)
    user.account_book_types << journal
    report              = Pack::Report.new
    report.name         = 'IDO%001 AC 201501'
    report.user         = user
    report.organization = organization
    report.save

    @preseizure              = Pack::Report::Preseizure.new
    @preseizure.date         = '2015-01-13'
    @preseizure.third_party  = 'TIERS'
    @preseizure.piece_number = '123'
    @preseizure.user         = user
    @preseizure.organization = organization
    @preseizure.save
    report.preseizures << @preseizure

    account        = Pack::Report::Preseizure::Account.new
    account.type   = 1
    account.number = "1TES"
    account.save
    @preseizure.accounts << account
    entry        = Pack::Report::Preseizure::Entry.new
    entry.type   = 2
    entry.amount = 24.0
    entry.number = '1'
    entry.save
    account.entries << entry
    @preseizure.entries << entry

    account        = Pack::Report::Preseizure::Account.new
    account.type   = 2
    account.number = "2TES"
    account.save
    @preseizure.accounts << account
    entry        = Pack::Report::Preseizure::Entry.new
    entry.type   = 1
    entry.amount = 20.0
    entry.number = '2'
    entry.save
    account.entries << entry
    @preseizure.entries << entry

    account        = Pack::Report::Preseizure::Account.new
    account.type   = 3
    account.number = "3TES"
    account.save
    @preseizure.accounts << account
    entry        = Pack::Report::Preseizure::Entry.new
    entry.type   = 1
    entry.amount = 4.0
    entry.number = '3'
    entry.save
    account.entries << entry
    @preseizure.entries << entry

    pack               = Pack.new
    pack.owner         = user
    pack.name          = report.name + ' all'
    pack.save
    piece              = Pack::Piece.new
    piece.pack         = pack
    piece.user         = user
    piece.organization = organization
    piece.name         = report.name + ' 001'
    piece.origin       = 'upload'
    piece.position     = 1
    piece.save

    @preseizure.piece = piece
    @preseizure.save
  end

  it 'should match' do
    allow_any_instance_of(User).to receive_message_chain('options.pre_assignment_date_computed?').and_return(false)
    result = PreseizureExport::PreseizureToTxt.new(@preseizure).execute
    lines  = result.split("\n")
    expect(lines.size).to eq 3
    expect(lines[0]).to eq 'M1TES    AC000130115 TIERS - 123         C+000000002400                                                    EUR                                                                       1.pdf                                                                      '
    expect(lines[1]).to eq 'M2TES    AC000130115 TIERS - 123         D+000000002000                                                    EUR                                                                       1.pdf                                                                      '
    expect(lines[2]).to eq 'M3TES    AC000130115 TIERS - 123         D+000000000400                                                    EUR                                                                       1.pdf                                                                      '
  end

  it 'should match without label' do
    allow_any_instance_of(User).to receive_message_chain('options.pre_assignment_date_computed?').and_return(false)
    @preseizure.piece_number = ''
    @preseizure.third_party  = ''
    result = PreseizureExport::PreseizureToTxt.new(@preseizure).execute
    lines = result.split("\n")
    expect(lines.size).to eq 3
    expect(lines[0]).to eq 'M1TES    AC000130115                     C+000000002400                                                    EUR                                                                       1.pdf                                                                      '
    expect(lines[1]).to eq 'M2TES    AC000130115                     D+000000002000                                                    EUR                                                                       1.pdf                                                                      '
    expect(lines[2]).to eq 'M3TES    AC000130115                     D+000000000400                                                    EUR                                                                       1.pdf                                                                      '
  end

  it 'with label size exceeding 30 characters, should have one line each that should match' do
    @preseizure.piece_number = '012345678910111213141516171819202122'
    @preseizure.third_party  = 'TIERS'
    lines = PreseizureExport::PreseizureToTxt.new(@preseizure).execute.split("\n")
    expect(lines.size).to eq 3
    expect(lines[0]).to eq 'M1TES    AC000130115 TIERS - 012345678910C+000000002400                                                    EUR      TIERS - 0123456789101112131415                                   1.pdf                                                                      '
    expect(lines[1]).to eq 'M2TES    AC000130115 TIERS - 012345678910D+000000002000                                                    EUR      TIERS - 0123456789101112131415                                   1.pdf                                                                      '
    expect(lines[2]).to eq 'M3TES    AC000130115 TIERS - 012345678910D+000000000400                                                    EUR      TIERS - 0123456789101112131415                                   1.pdf                                                                      '
  end

  it 'has an account number longer than 8 characters' do
    @preseizure.accounts.destroy_all
    @preseizure.reload

    account = Pack::Report::Preseizure::Account.new
    account.type   = 1
    account.number = 'NUMBER789'
    account.save
    @preseizure.accounts << account
    entry        = Pack::Report::Preseizure::Entry.new
    entry.type   = 2
    entry.amount = 24.0
    entry.number = '1'
    entry.save
    account.entries << entry
    @preseizure.entries << entry

    result = PreseizureExport::PreseizureToTxt.new(@preseizure).execute
    lines  = result.split("\n")
    expect(lines.size).to eq 1
    expect(lines[0]).to eq 'MNUMBER78AC000130115 TIERS - 123         C+000000002400                                                    EUR                                                                       1.pdf                                                                      '
  end
end

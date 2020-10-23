require 'spec_helper.rb'

describe 'IbizaLib::Api::Utils' do
  before(:each) do
    DatabaseCleaner.start
    Timecop.freeze(Time.local(2020,10,22))

    organization = FactoryBot.create :organization, code: 'IDO'
    user         = FactoryBot.create :user, code: 'IDO%LEAD', organization_id: organization.id, ibiza_id: '{595450CA-6F48-4E88-91F0-C225A95F5F16}'
    report       = FactoryBot.create :report, user: user, organization: organization, name: 'AC0003 AC 202010'
    pack         = FactoryBot.create :pack, owner: user, organization: organization , name: (report.name + ' all')
    piece        = FactoryBot.create :piece, pack: pack, user: user, organization: organization, name: (report.name + ' 001')
    @preseizure  = FactoryBot.create :preseizure, user: user, organization: organization, report_id: report.id, piece: piece

    @ibiza = Ibiza.create(
      state: 'valid',
      state_2: 'none',
      is_auto_deliver: true,
      description: JSON.parse('{"operation_label":{"is_used":"1", "position":"1"}, "date":{"is_used":"1", "position":"1"}, "third_party":{"is_used":"1", "position":"1"}, "amount":{"is_used":"1", "position":"1"}, "currency":{"is_used":"1", "position":"1"}, "conversion_rate":{"is_used":"1", "position":"1"}, "observation":{"is_used":"1", "position":"1"}, "journal":{"is_used":"1", "position":"1"}, "piece_name":{"is_used":"1", "position":"1"}, "piece_number":{"position":"1"}}'),
      description_separator: ' - ',
      piece_name_format: JSON.parse('{"code":{"position":"1"}, "code_wp":{"position":"1"}, "journal":{"position":"1"}, "period":{"position":"1"}, "number":{"position":"1"}}'),
      piece_name_format_sep: ' ',
      organization_id: organization.id
    )
  end

  after(:each) do
    Timecop.return
    DatabaseCleaner.clean
  end

  context '' do
    it 'returns description and piece name' do
      expect(IbizaLib::Api::Utils.description(@preseizure, @ibiza.description, @ibiza.description_separator)).to eq('2020-10-21 - 500.25 - AC - AC0003 AC 202010 001')
      expect(IbizaLib::Api::Utils.piece_name(@preseizure.piece.name, @ibiza.piece_name_format , @ibiza.piece_name_format_sep)).to eq('AC0003 AC 202010 001')
    end
  end

  context 'to xml import', :xml_generation do
    before(:each) do
      @exercise = OpenStruct.new(start_date: Time.now, end_date: Time.now)
      @analytic_reference = AnalyticReference.create(
        a1_name: "A1Name",
        a1_references: '[{"ventilation":"25","axis1":"AACE","axis2":"AXIS2","axis3":"AXIS3"},{"ventilation":"25","axis1":"CCR","axis2":null,"axis3":null},{"ventilation":"50","axis1":"HON","axis2":null,"axis3":null}]',
        a1_ventilation: 50,
        a1_axis1: "ax1_test_1",
        a1_axis2: "ax1_test_2",
        a2_name: "name2",
        a2_ventilation: 50,
        a2_axis1: "ax2_test_1"
      )
      @preseizure.piece.update(analytic_reference: @analytic_reference)

      @accounts  = Pack::Report::Preseizure::Account.create([
        { type: 1, number: '601109', preseizure_id: @preseizure.id },
        { type: 2, number: '471000', preseizure_id: @preseizure.id },
        { type: 3, number: '471001', preseizure_id: @preseizure.id },
      ])
      entries  = Pack::Report::Preseizure::Entry.create([
        { type: 1, number: '1', amount: 1213.48, preseizure_id: @preseizure.id, account_id: @accounts[0].id },
        { type: 2, number: '1', amount: 1011.23, preseizure_id: @preseizure.id, account_id: @accounts[1].id },
        { type: 2, number: '1', amount: 202.25, preseizure_id: @preseizure.id, account_id: @accounts[2].id },
      ])

      allow_any_instance_of(Pack::Report::Preseizure).to receive(:report).and_return(OpenStruct.new)
      allow_any_instance_of(Pack::Report::Preseizure).to receive(:is_period_range_used).and_return(false)
    end

    it 'generates an ibiza xml file with analytic node' do
      xml = IbizaLib::Api::Utils.to_import_xml(@exercise, [@preseizure], @ibiza, true)

      expect(xml[:data_built]).to match /<?xml/
      expect(xml[:data_built]).to match /importEntryRequest/
      expect(xml[:data_built]).to match /importAnalyticalEntries/
      expect(xml[:data_built]).to match /<analysis>A1Name<\/analysis>/
      expect(xml[:data_built]).to match /<axis1>CCR<\/axis1>/
      expect(xml[:data_built]).to match /<debit>1213.48<\/debit>/
      expect(xml[:data_built]).to match /<piece>AC0003 AC 202010 001<\/piece>/
      expect(xml[:data_built]).to match /<accountName>471000<\/accountName>/
      expect(xml[:data_built]).to match /<credit>505.615<\/credit>/
    end

    it 'does not generate analitic node, if accounts amount is not HT' do
      @accounts.each do |account|
        account.type = 1
        account.save
      end
      xml = IbizaLib::Api::Utils.to_import_xml(@exercise, [@preseizure.reload])

      expect(xml[:data_built]).to match /<?xml/
      expect(xml[:data_built]).to match /importEntryRequest/
      expect(xml[:data_built]).not_to match /importAnalyticalEntries/
      expect(xml[:data_built]).not_to match /<analysis>A1Name<\/analysis>/
      expect(xml[:data_built]).not_to match /<axis1>CCR<\/axis1>/
    end
  end
end

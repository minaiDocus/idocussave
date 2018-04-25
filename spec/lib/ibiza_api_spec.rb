require 'spec_helper.rb'

describe 'IbizaAPI::Utils' do
  describe '.computed_date', :computed_date do
    before(:each) do
      @preseizure = OpenStruct.new
      @exercise = OpenStruct.new
    end

    context 'when no range applies' do
      before(:each) do
        @preseizure.is_period_range_used = false
        @exercise.start_date = Date.new(2014,1,10)
        @exercise.end_date = Date.new(2015,1,9)
      end

      it 'returns preseizure date' do
        @preseizure.date = Date.new(2014,1,15)
        expect(IbizaAPI::Utils.computed_date(@preseizure, @exercise)).to eq(@preseizure.date)
      end

      it 'returns exercise start date' do
        @preseizure.date = Date.new(2014,1,5)
        expect(IbizaAPI::Utils.computed_date(@preseizure, @exercise)).to eq(@exercise.start_date)
      end

      it 'returns exercise end date' do
        @preseizure.date = Date.new(2015,1,20)
        expect(IbizaAPI::Utils.computed_date(@preseizure, @exercise)).to eq(@exercise.end_date)
      end

      it 'returns preseizure date' do
        @preseizure.date = Date.new(2015,1,20)
        @exercise.next = true
        expect(IbizaAPI::Utils.computed_date(@preseizure, @exercise)).to eq(@preseizure.date)
      end
    end

    context 'when period range applies' do
      before(:each) do
        @preseizure.is_period_range_used = true
        @exercise.start_date = Date.new(2014,1,1)
        @exercise.end_date = Date.new(2014,12,31)
      end

      context 'when preseizure date is nil' do
        before(:each) do
          @preseizure.date = nil
        end

        it 'returns period start date' do
          @preseizure.period_start_date = Date.new(2014,1,15)
          expect(IbizaAPI::Utils.computed_date(@preseizure, @exercise)).to eq(@preseizure.period_start_date)
        end
      end

      context 'when preseizure date is inside range' do
        before(:each) do
          @preseizure.period_start_date = Date.new(2014,1,1)
          @preseizure.date              = Date.new(2014,2,1)
          @preseizure.period_end_date   = Date.new(2014,3,1)
        end

        it 'returns preseizure date' do
          expect(IbizaAPI::Utils.computed_date(@preseizure, @exercise)).to eq(@preseizure.date)
        end
      end

      context 'when preseizure date is less than period start date' do
        before(:each) do
          @preseizure.date              = Date.new(2014,1,1)
          @preseizure.period_start_date = Date.new(2014,2,1)
          @preseizure.period_end_date   = Date.new(2014,3,1)
        end

        it 'returns period start date' do
          expect(IbizaAPI::Utils.computed_date(@preseizure, @exercise)).to eq(@preseizure.period_start_date)
        end
      end

      context 'when preseizure date is greater than period end date' do
        before(:each) do
          @preseizure.period_start_date = Date.new(2014,1,1)
          @preseizure.period_end_date   = Date.new(2014,2,1)
          @preseizure.date              = Date.new(2014,3,1)
        end

        it 'returns period start date' do
          expect(IbizaAPI::Utils.computed_date(@preseizure, @exercise)).to eq(@preseizure.period_start_date)
        end
      end
    end
  end

  describe 'ibiza xml generation', :xml_generation do
    before(:each) do
        @exercise = OpenStruct.new(start_date: Time.now, end_date: Time.now)
        @preseizure = create :preseizure
        @analytic_reference = AnalyticReference.create(
          a1_name: "name1",
          a1_ventilation: 50,
          a1_axis1: "ax1_test_1",
          a1_axis2: "ax1_test_2",
          a2_name: "name2",
          a2_ventilation: 50,
          a2_axis1: "ax2_test_1"
        )
        @preseizure.piece.update(analytic_reference: @analytic_reference)

        entry_1 = create :entry, type: 1, amount: 125.25
        entry_2 = create :entry, type: 2, amount: 125.25

        @accounts = create_list :account, 2
        @accounts[0].entries << entry_1
        @accounts[1].entries << entry_2
        @accounts.each do |account|
          account.number = "ABCDEF123"
          account.type = 2
          account.save
        end

        @preseizure.update(entries: [entry_1, entry_2])
        @preseizure.update(accounts: @accounts)

        allow_any_instance_of(Pack::Report::Preseizure).to receive(:report).and_return(OpenStruct.new)
        allow_any_instance_of(Pack::Report::Preseizure).to receive(:is_period_range_used).and_return(false)
      end

      it 'generates an ibiza xml file with analytic node' do
        xml = IbizaAPI::Utils.to_import_xml(@exercise, [@preseizure])

        expect(xml).to match /<\?xml/
        expect(xml).to match /importEntryRequest/
        expect(xml).to match /importAnalyticalEntries/
        expect(xml).to match /<analysis>name1<\/analysis>/
        expect(xml).to match /<axis1>ax1_test_1<\/axis1>/
        expect(xml).to match /<debit>62.625<\/debit>/
      end

      it 'does not generate analitic node, if accounts amount is not HT' do
        @accounts.each do |account|
          account.type = 1
          account.save
        end
        xml = IbizaAPI::Utils.to_import_xml(@exercise, [@preseizure.reload])

        expect(xml).to match /<\?xml/
        expect(xml).to match /importEntryRequest/
        expect(xml).not_to match /importAnalyticalEntries/
        expect(xml).not_to match /<analysis>name1<\/analysis>/
        expect(xml).not_to match /<axis1>ax1_test_1<\/axis1>/
      end
  end
end

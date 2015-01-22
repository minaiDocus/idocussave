require 'spec_helper.rb'

describe 'IbizaAPI::Utils' do
  describe '.computed_date' do
    before(:each) do
      @preseizure = OpenStruct.new
    end

    context 'when no range applies' do
      before(:each) do
        @preseizure.is_period_range_used = false
      end

      it 'return preseizure date' do
        @preseizure.date = Date.new(2014,1,15)
        expect(IbizaAPI::Utils.computed_date(@preseizure)).to eq(@preseizure.date)
      end
    end

    context 'when period range applies' do
      before(:each) do
        @preseizure.is_period_range_used = true
      end

      context 'when preseizure date is nil' do
        before(:each) do
          @preseizure.date = nil
        end

        it 'return period start date' do
          @preseizure.period_start_date = Date.new(2014,1,15)
          expect(IbizaAPI::Utils.computed_date(@preseizure)).to eq(@preseizure.period_start_date)
        end
      end

      context 'when preseizure date is inside range' do
        before(:each) do
          @preseizure.period_start_date = Date.new(2014,1,1)
          @preseizure.date              = Date.new(2014,2,1)
          @preseizure.period_end_date   = Date.new(2014,3,1)
        end

        it 'return preseizure date' do
          expect(IbizaAPI::Utils.computed_date(@preseizure)).to eq(@preseizure.date)
        end
      end

      context 'when preseizure date is less than period start date' do
        before(:each) do
          @preseizure.date              = Date.new(2014,1,1)
          @preseizure.period_start_date = Date.new(2014,2,1)
          @preseizure.period_end_date   = Date.new(2014,3,1)
        end

        it 'return period start date' do
          expect(IbizaAPI::Utils.computed_date(@preseizure)).to eq(@preseizure.period_start_date)
        end
      end

      context 'when preseizure date is greater than period end date' do
        before(:each) do
          @preseizure.period_start_date = Date.new(2014,1,1)
          @preseizure.period_end_date   = Date.new(2014,2,1)
          @preseizure.date              = Date.new(2014,3,1)
        end

        it 'return period start date' do
          expect(IbizaAPI::Utils.computed_date(@preseizure)).to eq(@preseizure.period_start_date)
        end
      end
    end
  end
end

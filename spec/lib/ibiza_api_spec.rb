require 'spec_helper.rb'

describe 'IbizaAPI::Utils' do
  describe '.computed_date' do
    before(:each) do
      @preseizure = OpenStruct.new
      @exercice   = OpenStruct.new
    end

    context 'when no range applies' do
      before(:each) do
        @preseizure.is_exercice_range_used = false
        @preseizure.is_period_range_used   = false
      end

      it 'return preseizure date' do
        @preseizure.date = Date.new(2014,1,15)
        expect(IbizaAPI::Utils.computed_date(@preseizure, @exercice)).to eq(@preseizure.date)
      end
    end

    context 'when period range applies' do
      before(:each) do
        @preseizure.is_exercice_range_used = false
        @preseizure.is_period_range_used   = true
      end

      context 'when preseizure date is nil' do
        before(:each) do
          @preseizure.date = nil
        end

        it 'return period start date' do
          @preseizure.period_start_date = Date.new(2014,1,15)
          expect(IbizaAPI::Utils.computed_date(@preseizure, @exercice)).to eq(@preseizure.period_start_date)
        end
      end

      context 'when preseizure date is inside range' do
        before(:each) do
          @preseizure.period_start_date = Date.new(2014,1,1)
          @preseizure.date              = Date.new(2014,2,1)
          @preseizure.period_end_date   = Date.new(2014,3,1)
        end

        it 'return preseizure date' do
          expect(IbizaAPI::Utils.computed_date(@preseizure, @exercice)).to eq(@preseizure.date)
        end
      end

      context 'when preseizure date is less than period start date' do
        before(:each) do
          @preseizure.date              = Date.new(2014,1,1)
          @preseizure.period_start_date = Date.new(2014,2,1)
          @preseizure.period_end_date   = Date.new(2014,3,1)
        end

        it 'return period start date' do
          expect(IbizaAPI::Utils.computed_date(@preseizure, @exercice)).to eq(@preseizure.period_start_date)
        end
      end

      context 'when preseizure date is greater than period end date' do
        before(:each) do
          @preseizure.period_start_date = Date.new(2014,1,1)
          @preseizure.period_end_date   = Date.new(2014,2,1)
          @preseizure.date              = Date.new(2014,3,1)
        end

        it 'return period start date' do
          expect(IbizaAPI::Utils.computed_date(@preseizure, @exercice)).to eq(@preseizure.period_start_date)
        end
      end
    end

    context 'when exercice range applies' do
      before(:each) do
        @preseizure.is_exercice_range_used = true
        @preseizure.is_period_range_used   = false
      end

      context 'when preseizure date is nil' do
        before(:each) do
          @preseizure.date = nil
        end

        it 'return exercice start date' do
          @exercice.start_date = Date.new(2014,3,15)
          expect(IbizaAPI::Utils.computed_date(@preseizure, @exercice)).to eq(@exercice.start_date)
        end
      end

      context 'when preseizure date is inside range' do
        before(:each) do
          @exercice.start_date = Date.new(2014,1,1)
          @preseizure.date     = Date.new(2014,2,1)
          @exercice.end_date   = Date.new(2014,3,1)
        end

        it 'return preseizure date' do
          expect(IbizaAPI::Utils.computed_date(@preseizure, @exercice)).to eq(@preseizure.date)
        end
      end

      context 'when preseizure date < exercice start date' do
        before(:each) do
          @preseizure.date     = Date.new(2014,1,1)
          @exercice.start_date = Date.new(2014,2,1)
          @exercice.end_date   = Date.new(2014,3,1)
        end

        it 'return exercice start date' do
          expect(IbizaAPI::Utils.computed_date(@preseizure, @exercice)).to eq(@exercice.start_date)
        end
      end

      context 'when preseizure date > exercice end date' do
        before(:each) do
          @exercice.start_date = Date.new(2014,1,1)
          @exercice.end_date   = Date.new(2014,2,1)
          @preseizure.date     = Date.new(2014,3,1)
        end

        it 'return exercice start date' do
          expect(IbizaAPI::Utils.computed_date(@preseizure, @exercice)).to eq(@exercice.start_date)
        end
      end
    end

    context 'when both ranges applies' do
      before(:each) do
        @preseizure.is_exercice_range_used = true
        @preseizure.is_period_range_used   = true
      end

      context 'when preseizure date is inside range' do
        before(:each) do
          @exercice.start_date          = Date.new(2014,1,1)
          @preseizure.period_start_date = Date.new(2014,2,1)
          @preseizure.date              = Date.new(2014,3,1)
          @preseizure.period_end_date   = Date.new(2014,4,1)
          @exercice.end_date            = Date.new(2014,5,1)
        end

        it 'return preseizure date' do
          expect(IbizaAPI::Utils.computed_date(@preseizure, @exercice)).to eq(@preseizure.date)
        end
      end

      context 'when preseizure date > period start date but preseizure date < exercice start date' do
        before(:each) do
          @exercice.start_date          = Date.new(2014,1,1)
          @preseizure.date              = Date.new(2014,2,1)
          @preseizure.period_start_date = Date.new(2014,3,1)
          @preseizure.period_end_date   = Date.new(2014,4,1)
          @exercice.end_date            = Date.new(2014,5,1)
        end

        it 'return period start date' do
          expect(IbizaAPI::Utils.computed_date(@preseizure, @exercice)).to eq(@preseizure.period_start_date)
        end
      end

      context 'when preseizure date < period end date but preseizure date > exercice end date' do
        before(:each) do
          @exercice.start_date          = Date.new(2014,1,1)
          @preseizure.period_start_date = Date.new(2014,2,1)
          @preseizure.period_end_date   = Date.new(2014,3,1)
          @preseizure.date              = Date.new(2014,4,1)
          @exercice.end_date            = Date.new(2014,5,1)
        end

        it 'return period start date' do
          expect(IbizaAPI::Utils.computed_date(@preseizure, @exercice)).to eq(@preseizure.period_start_date)
        end
      end

      context 'when preseizure date > period start date and preseizure date > exercice start date' do
        before(:each) do
          @preseizure.date              = Date.new(2014,1,1)
          @exercice.start_date          = Date.new(2014,2,1)
          @preseizure.period_start_date = Date.new(2014,3,1)
          @preseizure.period_end_date   = Date.new(2014,4,1)
          @exercice.end_date            = Date.new(2014,5,1)
        end

        it 'return exercice start date' do
          expect(IbizaAPI::Utils.computed_date(@preseizure, @exercice)).to eq(@exercice.start_date)
        end
      end

      context 'when preseizure date < period end date and preseizure date < exercice end date' do
        before(:each) do
          @exercice.start_date          = Date.new(2014,1,1)
          @preseizure.period_start_date = Date.new(2014,2,1)
          @preseizure.period_end_date   = Date.new(2014,3,1)
          @exercice.end_date            = Date.new(2014,4,1)
          @preseizure.date              = Date.new(2014,5,1)
        end

        it 'return exercice start date' do
          expect(IbizaAPI::Utils.computed_date(@preseizure, @exercice)).to eq(@exercice.start_date)
        end
      end
    end
  end
end

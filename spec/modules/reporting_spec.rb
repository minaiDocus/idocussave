require 'spec_helper'

describe Reporting do
  describe '.find_period_document' do
    before(:all) do
      DatabaseCleaner.start

      @user = FactoryBot.create(:user, code: 'TS%0001')

      @pack = Pack.create(name: 'TS%0001 TS 201702 all')
      @start_date = Date.parse('2017-02-01')
      @end_date = Date.parse('2017-02-28')
    end

    after(:all) { DatabaseCleaner.clean }

    it 'fails' do
      result = Reporting.find_period_document(@pack, @start_date, @end_date)
      expect(result).to eq nil
    end

    context 'one period_document is present' do
      before(:each) { DatabaseCleaner.start }
      after(:each) { DatabaseCleaner.clean }

      context 'and current date is 2017-02-15' do
        before(:each) do
          Timecop.freeze(Time.local(2017,2,15))
          @period_document = PeriodDocument.create(name: @pack.name, user: @user)
          Timecop.return
        end

        it "succeed with only pack's name" do
          result = Reporting.find_period_document(@pack, @start_date, @end_date)
          expect(result).to eq @period_document
        end

        it "succeed using pack's reference" do
          @pack.period_documents << @period_document
          result = Reporting.find_period_document(@pack, @start_date, @end_date)
          expect(result).to eq @period_document
        end

        it 'fails with dates out of range' do
          result = Reporting.find_period_document(@pack, Date.parse('2017-01-01'), Date.parse('2017-01-31'))
          expect(result).to eq nil
        end

        it 'fails with dates out of range' do
          result = Reporting.find_period_document(@pack, Date.parse('2017-03-01'), Date.parse('2017-03-31'))
          expect(result).to eq nil
        end
      end

      context 'and current date is 2017-02-01' do
        before(:each) do
          Timecop.freeze(Time.local(2017,2,1))
          @period_document = PeriodDocument.create(name: @pack.name, user: @user)
          Timecop.return
        end

        it 'fails' do
          result = Reporting.find_period_document(@pack, Date.parse('2017-01-01'), Date.parse('2017-01-31'))
          expect(result).to eq nil
        end

        it 'returns a period_document' do
          result = Reporting.find_period_document(@pack, @start_date, @end_date)
          expect(result).to eq @period_document
        end
      end

      context 'and current date is 2017-02-28' do
        before(:each) do
          Timecop.freeze(Time.local(2017,2,28,23,59,59))
          @period_document = PeriodDocument.create(name: @pack.name, user: @user)
          Timecop.return
        end

        it 'fails' do
          result = Reporting.find_period_document(@pack, Date.parse('2017-03-01'), Date.parse('2017-03-31'))
          expect(result).to eq nil
        end

        it 'returns a period_document' do
          result = Reporting.find_period_document(@pack, @start_date, @end_date)
          expect(result).to eq @period_document
        end
      end
    end
  end

  describe '.find_or_create_period_document' do
    before(:each) do
      DatabaseCleaner.start
      Timecop.freeze(Time.local(2017,2,15))

      @user = FactoryBot.create(:user, code: 'TS%0001')

      @pack = Pack.create(name: 'TS%0001 TS 201702 all', owner_id: @user.id)
      @period = Period.create(start_date: Date.parse('2017-02-01'))
    end

    after(:each) do
      Timecop.return
      DatabaseCleaner.clean
    end

    it 'returns a pre-existing period_document' do
      period_document = PeriodDocument.create(pack: @pack, name: @pack.name, period: @period, user: @user)

      expect(PeriodDocument).not_to receive(:new)
      result = Reporting.find_or_create_period_document(@pack, @period)
      expect(result).to eq period_document
    end

    it 'returns a pre-existing period_document and assign references' do
      period_document = PeriodDocument.create(name: @pack.name, user: @user)

      expect(PeriodDocument).not_to receive(:new)
      result = Reporting.find_or_create_period_document(@pack, @period)
      expect(result).to eq period_document
      expect(result.pack).to eq @pack
      expect(result.period).to eq @period
    end

    it 'creates a period_document' do
      user = create :user
      organization = create :organization
      organization.customers << user
      @pack.organization = organization
      @pack.owner = user
      @pack.save

      result = Reporting.find_or_create_period_document(@pack, @period)
      expect(result.class).to eq PeriodDocument
      expect(result.user).to eq user
      expect(result.organization).to eq organization
      expect(result.pack).to eq @pack
      expect(result.name).to eq @pack.name
      expect(result.period).to eq @period
    end
  end

  describe '.update' do
    shared_examples 'update period_document and period' do |period_duration|

      def updating(period_duration)
        times = case period_duration
        when 1
          [Time.local(2016,12), Time.local(2016,12,15), Time.local(2016,12,31,23,59,59)]
        when 3
          [Time.local(2016,10), Time.local(2016,10,15), Time.local(2016,12,31,23,59,59)]
        when 12
          [Time.local(2016,1), Time.local(2016,6,15), Time.local(2016,12,31,23,59,59)]
        end

        times.each_with_index do |time, index|
          Timecop.freeze(time)

          %w(scan upload dematbox_scan retriever).each_with_index do |origin, origin_index|
            %w(sheet piece).each do |type|
              if type == 'piece' || origin == 'scan'
                PackDivider.create(pack: @pack, type: type, origin: origin, name: 'DOC', pages_number: 2, position: 0)
              end
            end

            2.times do |page|
              Document.create(pack: @pack, origin: origin)
            end
          end
        end

        Reporting.update(@pack)
      end

      def updating_multiples(period_duration)
        times = case period_duration
        when 1
          [Time.local(2017,1), Time.local(2017,1,15), Time.local(2017,1,31,23,59,59)]
        when 3
          [Time.local(2017,1), Time.local(2017,1,15), Time.local(2017,3,31,23,59,59)]
        when 12
          [Time.local(2017,1), Time.local(2017,6,15), Time.local(2017,12,31,23,59,59)]
        end

        times.each_with_index do |time, i|
          Timecop.freeze(time)

          %w(sheet piece).each do |type|
            @pack.dividers.build(
              type:          type,
              origin:        'scan',
              name:          'DOC',
              pages_number:  2,
              position:      0
            ).save
          end

          2.times do |e|
            Document.create(pack: @pack, origin: 'scan')
          end
        end

        Reporting.update(@pack)
      end

      before(:each) do
        DatabaseCleaner.start
        Timecop.freeze(Time.local(2016,12))

        @user = FactoryBot.create(:user, code: 'TS%0001')
        @organization = FactoryBot.create(:organization, code: 'TS')
        @organization.customers << @user
        subscription = Subscription.create(user: @user, period_duration: period_duration, organization: @organization)
        @pack = Pack.create(owner: @user, name: 'TS%0001 TS 201612 all', organization: @organization)
      end

      after(:each) do
        Timecop.return
        DatabaseCleaner.clean
      end

      it 'creates 1 period_document' do
        updating period_duration

        expect(@pack.period_documents.size).to eq 1
      end

      it 'creates 1 period' do
        allow_any_instance_of(Subscription).to receive(:organization).and_return(false)
        updating period_duration

        expect(@user.periods.size).to eq 1
      end

      describe 'period_document' do
        subject { 
          updating period_duration
          @pack.period_documents.first 
        }

        it { expect(subject.pages).to eq 24 }
        it { expect(subject.pieces).to eq 12 }

        it { expect(subject.uploaded_pages).to eq 6 }
        it { expect(subject.uploaded_pieces).to eq 3 }

        it { expect(subject.scanned_pages).to eq 6 }
        it { expect(subject.scanned_pieces).to eq 3 }
        it { expect(subject.scanned_sheets).to eq 3 }

        it { expect(subject.retrieved_pages).to eq 6 }
        it { expect(subject.retrieved_pieces).to eq 3 }

        it { expect(subject.dematbox_scanned_pages).to eq 6 }
        it { expect(subject.dematbox_scanned_pieces).to eq 3 }
      end

      describe 'period' do
        subject { 
          allow_any_instance_of(Subscription).to receive(:organization).and_return(false)
          updating period_duration
          @user.periods.first
        }

        it {
          start_date = case period_duration
          when 1
            Date.parse('2016-12-01')
          when 3
            Date.parse('2016-10-01')
          when 12
            Date.parse('2016-01-01')
          end
          expect(subject.start_date).to eq start_date
        }

        it { expect(subject.end_date).to eq Date.parse('2016-12-31') }

        it { expect(subject.pages).to eq 24 }
        it { expect(subject.pieces).to eq 12 }

        it { expect(subject.uploaded_pages).to eq 6 }
        it { expect(subject.uploaded_pieces).to eq 3 }

        it { expect(subject.scanned_pages).to eq 6 }
        it { expect(subject.scanned_pieces).to eq 3 }
        it { expect(subject.scanned_sheets).to eq 3 }

        it { expect(subject.retrieved_pages).to eq 6 }
        it { expect(subject.retrieved_pieces).to eq 3 }

        it { expect(subject.dematbox_scanned_pages).to eq 6 }
        it { expect(subject.dematbox_scanned_pieces).to eq 3 }

        it { expect(subject.delivery_state).to eq 'delivered' }
      end

      describe 'and multiple period' do
        before(:each) do
          DatabaseCleaner.start
        end

        after(:each) { DatabaseCleaner.clean }

        it 'creates an additionnal period_document' do
          updating period_duration
          updating_multiples(period_duration)
          expect(@pack.period_documents.size).to eq 2
        end

        it 'creates an additionnal period' do
          allow_any_instance_of(Subscription).to receive(:organization).and_return(false)
          updating_multiples(period_duration)
          expect(@user.periods.size).to eq 2
        end

        describe 'period_document' do
          subject {
            updating_multiples(period_duration) 
            @pack.period_documents.last
          }

          it { expect(subject.pages).to eq 6 }
          it { expect(subject.pieces).to eq 3 }

          it { expect(subject.uploaded_pages).to eq 0 }
          it { expect(subject.uploaded_pieces).to eq 0 }

          it { expect(subject.scanned_pages).to eq 6 }
          it { expect(subject.scanned_pieces).to eq 3 }
          it { expect(subject.scanned_sheets).to eq 3 }

          it { expect(subject.retrieved_pages).to eq 0 }
          it { expect(subject.retrieved_pieces).to eq 0 }

          it { expect(subject.dematbox_scanned_pages).to eq 0 }
          it { expect(subject.dematbox_scanned_pieces).to eq 0 }
        end

        describe 'period' do
          subject {
            allow_any_instance_of(Subscription).to receive(:organization).and_return(false)
            updating_multiples(period_duration) 
            @user.periods.last
          }

          it { expect(subject.start_date).to eq Date.parse('2017-01-01') }

          it {
            end_date = case period_duration
            when 1
              Date.parse('2017-01-31')
            when 3
              Date.parse('2017-03-31')
            when 12
              Date.parse('2017-12-31')
            end
            expect(subject.end_date).to eq end_date
          }

          it { expect(subject.pages).to eq 6 }
          it { expect(subject.pieces).to eq 3 }

          it { expect(subject.uploaded_pages).to eq 0 }
          it { expect(subject.uploaded_pieces).to eq 0 }

          it { expect(subject.scanned_pages).to eq 6 }
          it { expect(subject.scanned_pieces).to eq 3 }
          it { expect(subject.scanned_sheets).to eq 3 }

          it { expect(subject.retrieved_pages).to eq 0 }
          it { expect(subject.retrieved_pieces).to eq 0 }

          it { expect(subject.dematbox_scanned_pages).to eq 0 }
          it { expect(subject.dematbox_scanned_pieces).to eq 0 }

          it { expect(subject.delivery_state).to eq 'delivered' }
        end
      end
    end

    context 'with a monthly subscription' do
      include_examples 'update period_document and period', 1
    end

    context 'with an annually subscription' do
      include_examples 'update period_document and period', 12
    end
  end
end

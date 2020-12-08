# -*- encoding : UTF-8 -*-
require 'spec_helper'

describe IbizaLib::ExerciseFinder do
  before(:all) do
    @time = Time.local(2015,2,1,0,0,0)
    @cache_name = 'ibiza_2015-02-01_00:00:00_+0300_{123456}_exercises'
  end

  before(:each) do
    Rails.cache.delete @cache_name
  end

  describe '#execute' do
    before(:all) do
      @user = create(:user)
    end

    context 'use local exercises' do
      before(:each) do
        @user.exercises.destroy_all
        @user.reload
      end

      context 'with empty exercises' do
        it 'returns nil' do
          expect(IbizaLib::ExerciseFinder.new(@user, Date.parse('15-01-2015')).execute).to be_nil
        end
      end

      context 'with closed exercise' do
        it 'returns nil' do
          exercise = Exercise.new
          exercise.user = @user
          exercise.start_date = Date.parse('01-02-2014')
          exercise.end_date = Date.parse('28-02-2015')
          exercise.is_closed = true
          exercise.save
          expect(IbizaLib::ExerciseFinder.new(@user, Date.parse('15-01-2015')).execute).to be_nil
        end
      end

      context 'with open exercises' do
        it 'returns an exercise' do
          exercise = Exercise.new
          exercise.user = @user
          exercise.start_date = Date.parse('01-02-2014')
          exercise.end_date = Date.parse('28-02-2015')
          exercise.is_closed = false
          exercise.save
          expect(IbizaLib::ExerciseFinder.new(@user, Date.parse('15-01-2015')).execute).to eq exercise
        end

        it 'returns the first exercise' do
          exercise = Exercise.new
          exercise.user = @user
          exercise.start_date = Date.parse('15-04-2014')
          exercise.end_date = Date.parse('14-04-2015')
          exercise.is_closed = false
          exercise.save
          exercise2 = Exercise.new
          exercise2.user = @user
          exercise2.start_date = Date.parse('15-04-2013')
          exercise2.end_date = Date.parse('14-04-2014')
          exercise2.is_closed = false
          exercise2.save
          expect(IbizaLib::ExerciseFinder.new(@user, Date.parse('10-04-2014')).execute).to eq exercise2
        end

        it 'returns the last exercise' do
          exercise = Exercise.new
          exercise.user = @user
          exercise.start_date = Date.parse('15-04-2014')
          exercise.end_date = Date.parse('14-04-2015')
          exercise.is_closed = false
          exercise.save
          exercise2 = Exercise.new
          exercise2.user = @user
          exercise2.start_date = Date.parse('15-04-2013')
          exercise2.end_date = Date.parse('14-04-2014')
          exercise2.is_closed = false
          exercise2.save
          expect(IbizaLib::ExerciseFinder.new(@user, Date.parse('20-04-2014')).execute).to eq exercise
        end

        context 'outside date range' do
          it 'returns nil' do
            exercise = Exercise.new
            exercise.user = @user
            exercise.start_date = Date.parse('01-01-2014')
            exercise.end_date = Date.parse('31-12-2014')
            exercise.is_closed = false
            exercise.save
            expect(IbizaLib::ExerciseFinder.new(@user, Date.parse('15-01-2015')).execute).to be_nil
          end

          it 'returns nil' do
            exercise = Exercise.new
            exercise.user = @user
            exercise.start_date = Date.parse('01-02-2015')
            exercise.end_date = Date.parse('31-01-2016')
            exercise.is_closed = false
            exercise.save
            expect(IbizaLib::ExerciseFinder.new(@user, Date.parse('15-01-2015')).execute).to be_nil
          end

          context 'but month start date is the same as date' do
            it 'returns an exercise' do
              exercise2 = Exercise.new
              exercise2.user = @user
              exercise2.start_date = Date.parse('20-03-2016')
              exercise2.end_date = Date.parse('19-03-2017')
              exercise2.is_closed = false
              exercise2.save
              exercise = Exercise.new
              exercise.user = @user
              exercise.start_date = Date.parse('20-03-2015')
              exercise.end_date = Date.parse('19-03-2016')
              exercise.is_closed = false
              exercise.save
              expect(IbizaLib::ExerciseFinder.new(@user, Date.parse('15-03-2015')).execute).to eq exercise
            end
          end

          context 'but month end date is the same as date' do
            it 'returns an exercise' do
              exercise2 = Exercise.new
              exercise2.user = @user
              exercise2.start_date = Date.parse('10-03-2014')
              exercise2.end_date = Date.parse('09-03-2015')
              exercise2.is_closed = false
              exercise2.save
              exercise = Exercise.new
              exercise.user = @user
              exercise.start_date = Date.parse('10-03-2013')
              exercise.end_date = Date.parse('09-03-2014')
              exercise.is_closed = false
              exercise.save
              expect(IbizaLib::ExerciseFinder.new(@user, Date.parse('15-03-2015')).execute).to eq exercise2
            end
          end
        end
      end
    end

    context 'use ibiza exercises' do
      context 'ibiza is not configured' do
        it 'returns false' do
          ibiza = Software::Ibiza.new
          expect(IbizaLib::ExerciseFinder.new(@user, Date.parse('15-01-2015'), ibiza).execute).to eq false
        end
      end

      context 'ibiza is configured' do
        it 'returns nil' do
          VCR.use_cassette('find_exercise/exercises') do
            ibiza = double('ibiza')
            allow(ibiza).to receive(:updated_at) { @time }
            allow(ibiza).to receive(:configured?) { true }
            allow(ibiza).to receive(:client) { IbizaLib::Api::Client.new('123456', nil) }
            @user.ibiza_id = '{123456}'

            exercise = IbizaLib::ExerciseFinder.new(@user, Date.parse('15-08-2014'), ibiza).execute

            expect(exercise).to be_nil
          end
        end

        it 'returns nil' do
          VCR.use_cassette('find_exercise/exercises') do
            ibiza = double('ibiza')
            allow(ibiza).to receive(:updated_at) { @time }
            allow(ibiza).to receive(:configured?) { true }
            allow(ibiza).to receive(:client) { IbizaLib::Api::Client.new('123456', nil) }
            @user.ibiza_id = '{123456}'

            exercise = IbizaLib::ExerciseFinder.new(@user, Date.parse('15-01-2016'), ibiza).execute

            expect(exercise).to be_nil
          end
        end

        it 'returns false with an error' do
          VCR.use_cassette('find_exercise/insufficient_rights') do
            ibiza = double('ibiza')
            allow(ibiza).to receive(:updated_at) { @time }
            allow(ibiza).to receive(:configured?) { true }
            client = IbizaLib::Api::Client.new('123456', nil)
            allow(ibiza).to receive(:client) { client }
            @user.ibiza_id = '{123456}'

            result = IbizaLib::ExerciseFinder.new(@user, Date.parse('15-01-2015'), ibiza).execute

            expect(result).to eq false
            expect(client.response.message).to eq({"error"=>{"details"=>"insufficient rights"}})
          end
        end

        it 'returns an exercise' do
          VCR.use_cassette('find_exercise/exercises') do
            ibiza = double('ibiza')
            allow(ibiza).to receive(:updated_at) { @time }
            allow(ibiza).to receive(:configured?) { true }
            allow(ibiza).to receive(:client) { IbizaLib::Api::Client.new('123456', nil) }
            @user.ibiza_id = '{123456}'

            exercise = IbizaLib::ExerciseFinder.new(@user, Date.parse('15-01-2015'), ibiza).execute

            expect(exercise).to be_present
            expect(exercise.start_date).to eq(Date.parse('01-09-2014'))
            expect(exercise.end_date).to eq(Date.parse('31-12-2015'))
            expect(exercise.is_closed).to eq(false)
          end
        end
      end
    end
  end

  describe '.ibiza_exercises' do
    it 'returns false' do
      VCR.use_cassette('find_exercise/insufficient_rights') do
        client = IbizaLib::Api::Client.new('123456', nil)

        result = IbizaLib::ExerciseFinder.ibiza_exercises(client, '{123456}', @time)

        expect(result).to eq false
      end
    end

    it 'returns 1 exercise' do
      VCR.use_cassette('find_exercise/exercises') do
        client = IbizaLib::Api::Client.new('123456', nil)

        exercises = IbizaLib::ExerciseFinder.ibiza_exercises(client, '{123456}', @time)
        exercise = exercises.first

        expect(exercises.size).to eq 1
        expect(exercise.start_date).to eq Date.parse('01-09-2014')
        expect(exercise.end_date).to eq Date.parse('31-12-2015')
        expect(exercise.is_closed).to eq false
      end
    end

    it 'write in the cache' do
      VCR.use_cassette('find_exercise/exercises') do
        client = IbizaLib::Api::Client.new('123456', nil)

        expect(Rails.cache.read(@cache_name)).to be_nil

        exercises = IbizaLib::ExerciseFinder.ibiza_exercises(client, '{123456}', @time)

        expect(Rails.cache.read(@cache_name)).to eq(exercises)
      end
    end
  end

  describe '.ibiza_exercises_cache_name' do
    it 'returns ibiza_{6FDCDD01-94DD-4780-84AA-1F0A64E1C257}_exercises' do
      cache_name = IbizaLib::ExerciseFinder.ibiza_exercises_cache_name '{6FDCDD01-94DD-4780-84AA-1F0A64E1C257}'
      expect(cache_name).to eq('ibiza_{6FDCDD01-94DD-4780-84AA-1F0A64E1C257}_exercises')
    end

    it 'returns ibiza_2015-01-01_00:00:01_+0300_{6FDCDD01-94DD-4780-84AA-1F0A64E1C257}_exercises' do
      cache_name = IbizaLib::ExerciseFinder.ibiza_exercises_cache_name '{6FDCDD01-94DD-4780-84AA-1F0A64E1C257}', Time.local(2015,1,1,0,0,1)
      expect(cache_name).to eq('ibiza_2015-01-01_00:00:01_+0300_{6FDCDD01-94DD-4780-84AA-1F0A64E1C257}_exercises')
    end
  end
end

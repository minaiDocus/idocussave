# -*- encoding : UTF-8 -*-
require 'spec_helper'

describe FindExercise do
  describe '#execute' do
    before(:all) do
      @user = create(:user)
    end

    context 'use local exercises' do
      before(:each) do
        @user.exercices.destroy_all
        @user.reload
      end

      context 'with empty exercises' do
        it 'returns nil' do
          expect(FindExercise.new(@user, Date.parse('15-1-2015')).execute).to be_nil
        end
      end

      context 'with closed exercise' do
        it 'returns nil' do
          exercise = Exercice.new
          exercise.user = @user
          exercise.start_date = Date.parse('1-2-2014')
          exercise.end_date = Date.parse('28-2-2015')
          exercise.is_closed = true
          exercise.save
          expect(FindExercise.new(@user, Date.parse('15-1-2015')).execute).to be_nil
        end
      end

      context 'with open exercises' do
        it 'returns an exercise' do
          exercise = Exercice.new
          exercise.user = @user
          exercise.start_date = Date.parse('1-2-2014')
          exercise.end_date = Date.parse('28-2-2015')
          exercise.is_closed = false
          exercise.save
          expect(FindExercise.new(@user, Date.parse('15-1-2015')).execute).to eq exercise
        end

        context 'outside date range' do
          it 'returns nil' do
            exercise = Exercice.new
            exercise.user = @user
            exercise.start_date = Date.parse('1-1-2014')
            exercise.end_date = Date.parse('31-12-2014')
            exercise.is_closed = false
            exercise.save
            expect(FindExercise.new(@user, Date.parse('15-1-2015')).execute).to be_nil
          end

          it 'returns nil' do
            exercise = Exercice.new
            exercise.user = @user
            exercise.start_date = Date.parse('1-2-2015')
            exercise.end_date = Date.parse('31-1-2016')
            exercise.is_closed = false
            exercise.save
            expect(FindExercise.new(@user, Date.parse('15-1-2015')).execute).to be_nil
          end
        end
      end
    end

    context 'use ibiza exercises' do
      context 'ibiza is not configured' do
        it 'returns false' do
          ibiza = Ibiza.new
          expect(FindExercise.new(@user, Date.parse('15-1-2015'), ibiza).execute).to eq false
        end
      end

      context 'ibiza is configured' do
        it 'returns nil' do
          VCR.use_cassette('find_exercise/exercises') do
            ibiza = double('ibiza')
            allow(ibiza).to receive(:updated_at) { Time.now }
            allow(ibiza).to receive(:is_configured?) { true }
            allow(ibiza).to receive(:client) { IbizaAPI::Client.new('123456') }
            @user.ibiza_id = '{123456}'

            exercise = FindExercise.new(@user, Date.parse('15-08-2014'), ibiza).execute

            expect(exercise).to be_nil
          end
        end

        it 'returns nil' do
          VCR.use_cassette('find_exercise/exercises') do
            ibiza = double('ibiza')
            allow(ibiza).to receive(:updated_at) { Time.local(2015,2,1,0,0,1) }
            allow(ibiza).to receive(:is_configured?) { true }
            allow(ibiza).to receive(:client) { IbizaAPI::Client.new('123456') }
            @user.ibiza_id = '{123456}'

            exercise = FindExercise.new(@user, Date.parse('15-01-2016'), ibiza).execute

            expect(exercise).to be_nil
          end
        end

        it 'returns false with an error' do
          VCR.use_cassette('find_exercise/insufficient_rights') do
            ibiza = double('ibiza')
            allow(ibiza).to receive(:updated_at) { Time.local(2015,2,1,0,0,2) }
            allow(ibiza).to receive(:is_configured?) { true }
            client = IbizaAPI::Client.new('123456')
            allow(ibiza).to receive(:client) { client }
            @user.ibiza_id = '{123456}'

            result = FindExercise.new(@user, Date.parse('15-01-2015'), ibiza).execute

            expect(result).to eq false
            expect(client.response.message).to eq({"error"=>{"details"=>"insufficient rights"}})
          end
        end

        it 'returns an exercise' do
          VCR.use_cassette('find_exercise/exercises') do
            ibiza = double('ibiza')
            allow(ibiza).to receive(:updated_at) { Time.local(2015,2,1,0,0,3) }
            allow(ibiza).to receive(:is_configured?) { true }
            allow(ibiza).to receive(:client) { IbizaAPI::Client.new('123456') }
            @user.ibiza_id = '{123456}'

            exercise = FindExercise.new(@user, Date.parse('15-1-2015'), ibiza).execute

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
        client = IbizaAPI::Client.new('123456')
        time = Time.local(2015,2,1,0,0,4)

        result = FindExercise.ibiza_exercises(client, '{123456}', time)

        expect(result).to eq false
      end
    end

    it 'returns 1 exercise' do
      VCR.use_cassette('find_exercise/exercises') do
        client = IbizaAPI::Client.new('123456')
        time = Time.local(2015,2,1,0,0,5)

        exercises = FindExercise.ibiza_exercises(client, '{123456}', time)
        exercise = exercises.first

        expect(exercises.size).to eq 1
        expect(exercise.start_date).to eq Date.parse('01-09-2014')
        expect(exercise.end_date).to eq Date.parse('31-12-2015')
        expect(exercise.is_closed).to eq false
      end
    end

    it 'write in the cache' do
      VCR.use_cassette('find_exercise/exercises') do
        client = IbizaAPI::Client.new('123456')
        time = Time.local(2015,2,1,0,0,6)
        cache_name = FindExercise.ibiza_exercises_cache_name('{123456}', time)

        expect(Rails.cache.read(cache_name)).to be_nil

        exercises = FindExercise.ibiza_exercises(client, '{123456}', time)

        expect(Rails.cache.read(cache_name)).to eq(exercises)
      end
    end
  end

  describe '.ibiza_exercises_cache_name' do
    it 'returns ibiza_{6FDCDD01-94DD-4780-84AA-1F0A64E1C257}_exercises' do
      cache_name = FindExercise.ibiza_exercises_cache_name '{6FDCDD01-94DD-4780-84AA-1F0A64E1C257}'
      expect(cache_name).to eq('ibiza_{6FDCDD01-94DD-4780-84AA-1F0A64E1C257}_exercises')
    end

    it 'returns ibiza_2015-01-01_00:00:01_+0300_{6FDCDD01-94DD-4780-84AA-1F0A64E1C257}_exercises' do
      cache_name = FindExercise.ibiza_exercises_cache_name '{6FDCDD01-94DD-4780-84AA-1F0A64E1C257}', Time.local(2015,1,1,0,0,1)
      expect(cache_name).to eq('ibiza_2015-01-01_00:00:01_+0300_{6FDCDD01-94DD-4780-84AA-1F0A64E1C257}_exercises')
    end
  end
end

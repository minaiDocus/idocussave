# -*- encoding : UTF-8 -*-
module IbizaLib
  class ExerciseFinder
    attr_accessor :user, :date, :ibiza

    def initialize(user, date, ibiza = nil)
      @user  = user
      @date  = date
      @ibiza = ibiza
    end

    def execute
      if @ibiza
        if @ibiza.configured?
          exercises = self.class.ibiza_exercises(@ibiza.client, @user.ibiza.ibiza_id, @ibiza.updated_at)
        else
          exercises = false
        end
      else
        exercises = @user.exercises
      end

      if exercises
        exercises = exercises.reject(&:is_closed).sort_by(&:start_date)

        result = exercises.select do |exercise|
          exercise.start_date <= @date && @date <= exercise.end_date
        end.first

        if result.nil?
          result = exercises.select do |exercise|
            exercise.start_date.beginning_of_month == @date.beginning_of_month ||
              exercise.end_date.beginning_of_month == @date.beginning_of_month
          end.first
        end

        result
      else
        false
      end
    end

    class << self
      def ibiza_exercises(client, id, time = nil)
        cache_name = ibiza_exercises_cache_name(id, time)

        exercises = Rails.cache.read(cache_name)

        if exercises
          exercises
        else
          client.request.clear
          client.company(id).exercices?
          if client.response.success?
            exercises = Array(client.response.data).map do |exercise_data|
              exercise = OpenStruct.new
              exercise.end_date   = exercise_data['end'].to_date
              exercise.is_closed  = exercise_data['state'].to_i == 2
              exercise.start_date = exercise_data['start'].to_date

              exercise
            end

            exercises.each do |exercise|
              exercise.prev = exercises.select { |e| e.end_date == exercise.start_date - 1.day }.first
              exercise.next = exercises.select { |e| e.start_date == exercise.end_date + 1.day }.first
            end
          else
            exercises = false
          end

          Rails.cache.write cache_name, exercises, expires_in: 1.hour if exercises

          exercises
        end
      end

      def ibiza_exercises_cache_name(id, time = nil)
        stime = time ? time.to_s.gsub(/\s+/, '_') : nil

        ['ibiza', stime, id, 'exercises'].compact.join('_')
      end
    end
  end
end

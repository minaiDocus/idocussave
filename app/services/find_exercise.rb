# -*- encoding : UTF-8 -*-
class FindExercise
  attr_accessor :user, :date, :ibiza

  def initialize(user, date, ibiza=nil)
    @user = user
    @date = date
    @ibiza = ibiza
  end

  def execute
    if @ibiza
      if @ibiza.is_configured?
        exercises = self.class.ibiza_exercises(@ibiza.client, @user.ibiza_id, @ibiza.updated_at)
      else
        exercises = false
      end
    else
      exercises = @user.exercises
    end
    if exercises
      exercises.reject(&:is_closed).select do |exercise|
        exercise.start_date <= @date && @date <= exercise.end_date
      end.first
    else
      false
    end
  end

  class << self
    def ibiza_exercises(client, id, time=nil)
      cache_name = ibiza_exercises_cache_name(id, time)
      exercises = Rails.cache.read(cache_name)
      if exercises
        exercises
      else
        client.request.clear
        client.company(id).exercices?
        if client.response.success?
          exercises = client.response.data.map do |exercise_data|
            exercise = OpenStruct.new
            exercise.start_date = exercise_data['start'].to_date
            exercise.end_date   = exercise_data['end'].to_date
            exercise.is_closed  = exercise_data['state'].to_i == 2
            exercise
          end
        else
          exercises = false
        end
        Rails.cache.write cache_name, exercises, expires_in: 1.hour if exercises
        exercises
      end
    end

    def ibiza_exercises_cache_name(id, time=nil)
      stime = time ? time.to_s.gsub(/\s+/,'_') : nil
      ['ibiza', stime, id, 'exercises'].compact.join('_')
    end
  end
end

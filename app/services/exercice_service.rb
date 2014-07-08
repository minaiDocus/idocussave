# -*- encoding : UTF-8 -*-
class ExerciceService
  class << self
    def all(user)
      results = []
      if user.organization.try(:ibiza).try(:is_configured?)
        begin
          results = user.organization.ibiza.exercices(user.ibiza_id).map do |exercice|
            obj = OpenStruct.new
            obj.start_date = exercice['start'].to_date
            obj.end_date = exercice['end'].to_date
            obj.is_closed = exercice['state'].to_i == 2
            obj
          end
        rescue Ibiza::NoExercicesFound
          results = nil
        end
      else
        results = user.exercices
      end
      results
    end

    def find(user, period, include_closed=true)
      results = all(user)
      if results
        results = results.reject(&:is_closed) unless include_closed
        results.select do |exercice|
          exercice.start_date < period && period < exercice.end_date
        end.first
      else
        results
      end
    end
  end
end

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

    def find(user, period, all=true)
      results = all(user)
      if results
        results = results.reject(&:is_closed) unless all
        results.select do |exercice|
          exercice.start_date < period && exercice.end_date > period
        end.first
      else
        results
      end
    end
  end
end

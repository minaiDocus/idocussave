class PreAssignment::Builder::Ibiza < PreAssignment::Builder::DataService
  def self.execute(delivery)
    new(delivery).run
  end

  def initialize(delivery)
    super

    @software = @delivery.organization.ibiza
  end

  private

  def execute
    @delivery.building_data

    if ibiza_exercise
      response = IbizaLib::Api::Utils.to_import_xml(ibiza_exercise, @preseizures, @software, (@delivery.error_message == 'force sending'))

      if response[:data_count] > 0
        save_data_to_storage(response[:data_built], 'xml')

        building_success response[:data_count]
      else
        building_failed 'No preseizure to send'
      end
    else
      if is_ibiza_exercises_present?
        error_message = "L'exercice correspondant n'est pas défini dans iBiza."
      else
        if @software.client.response.message.to_s.size > 255
          error_message = 'Erreur inconnu.'
        else
          error_message = @software.client.response.message.to_s.presence || @software.client.response.status.to_s
        end
      end

      building_failed error_message
    end
  end

  def grouped_date
    first_date = @preseizures.map(&:date).compact.sort.first

    return first_date.to_date if @preseizures.first.operation

    if first_date && @delivery.grouped_date.year == first_date.year && @delivery.grouped_date.month == first_date.month
      first_date.to_date
    else
      @delivery.grouped_date
    end
  end

  def ibiza_exercise
    @ibiza_exercise ||= IbizaLib::ExerciseFinder.new(@user, grouped_date, @software).execute
  end

  def is_ibiza_exercises_present?
    Rails.cache.read(IbizaLib::ExerciseFinder.ibiza_exercises_cache_name(@user.try(:ibiza).try(:ibiza_id), @software.updated_at)).present?
  end
end
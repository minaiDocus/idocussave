# Ibiza delivery's xml for a specific pre assignment delivery
class PreAssignmentDeliveryXmlBuilder
  def initialize(delivery_id)
    @delivery    = PreAssignmentDelivery.find(delivery_id)

    @user        = @delivery.user
    @ibiza       = @delivery.organization.ibiza
    @report      = @delivery.report
    @preseizures = @delivery.preseizures
  end


  def execute
    @delivery.building_xml

    if exercise
      @delivery.xml_data = IbizaAPI::Utils.to_import_xml(exercise, @preseizures, @ibiza.description, @ibiza.description_separator, @ibiza.piece_name_format, @ibiza.piece_name_format_sep)

      @delivery.save

      @delivery.xml_built
    else
      if is_exercises_present?
        @delivery.error_message = @report.delivery_message = "L'exercice correspondant n'est pas défini dans iBiza."
      else
        @delivery.error_message = @report.delivery_message = @ibiza.client.response.message.to_s
      end

      @report.save
      @delivery.save
      @delivery.error

      time = Time.now

      @preseizures.each do |preseizure|
        preseizure.delivery_tried_at = time
        preseizure.delivery_message  = @report.delivery_message
        preseizure.is_locked         = false
        preseizure.save
      end

      @report.delivery_tried_at = time
      @report.is_locked         = false
      @report.save

      notify

      false
    end
  end


  def grouped_date
    first_date = @preseizures.map(&:date).compact.sort.first

    if first_date && @delivery.grouped_date.year == first_date.year && @delivery.grouped_date.month == first_date.month
      first_date.to_date
    else
      @delivery.grouped_date
    end
  end


  def exercise
    @exercise ||= IbizaExerciseFinder.new(@user, grouped_date, @ibiza).execute
  end


  def is_exercises_present?
    Rails.cache.read(IbizaExerciseFinder.ibiza_exercises_cache_name(@user.ibiza_id, @ibiza.updated_at)).present?
  end
end

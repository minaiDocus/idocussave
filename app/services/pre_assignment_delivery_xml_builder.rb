# Delivery's xml for a specific pre assignment delivery
class PreAssignmentDeliveryXmlBuilder
  def initialize(delivery_id)
    @delivery    = PreAssignmentDelivery.find(delivery_id)

    @user        = @delivery.user
    @software    = @delivery.deliver_to == 'ibiza' ? @delivery.organization.ibiza : @delivery.user.exact_online
    @report      = @delivery.report
    @preseizures = @delivery.preseizures
  end


  def execute
    if @delivery.deliver_to == 'ibiza'
      build_for_ibiza
    else
      build_for_exact_online
    end
  end


  def build_for_ibiza
    @delivery.building_data

    if ibiza_exercise
      @delivery.data_to_deliver = IbizaAPI::Utils.to_import_xml(ibiza_exercise, @preseizures, @software)
      @delivery.save
      @delivery.data_built
    else
      if is_ibiza_exercises_present?
        error_message = "L'exercice correspondant n'est pas défini dans iBiza."
      else
        if @software.client.response.message.to_s.size > 255
          error_message = 'Erreur inconnu.'
        else
          error_message = @software.client.response.message.to_s
        end
      end

      building_failed error_message
    end
  end

  def build_for_exact_online
    @delivery.building_data
    response = ExactOnlineDataBuilder.new(@delivery).execute

    if response[:data_built]
      @delivery.data_to_deliver = response[:data]
      @delivery.save
      @delivery.data_built
    else
      building_failed response[:error_messages]
    end
  end

  private

  def building_failed(error_message)
    @delivery.error_message = error_message
    @delivery.save
    @delivery.error

    time = Time.now

    @preseizures.each do |preseizure|
      preseizure.delivery_tried_at = time
      preseizure.is_locked         = false
      preseizure.save
      preseizure.set_delivery_message_for(@delivery.deliver_to, error_message)
    end

    @report.delivery_tried_at = time
    @report.is_locked         = false
    @report.save
    @report.set_delivery_message_for(@delivery.deliver_to, error_message)

    PreAssignmentDeliveryService.notify

    false
  end

  def grouped_date
    first_date = @preseizures.map(&:date).compact.sort.first

    if first_date && @delivery.grouped_date.year == first_date.year && @delivery.grouped_date.month == first_date.month
      first_date.to_date
    else
      @delivery.grouped_date
    end
  end


  def ibiza_exercise
    @ibiza_exercise ||= IbizaExerciseFinder.new(@user, grouped_date, @software).execute
  end


  def is_ibiza_exercises_present?
    Rails.cache.read(IbizaExerciseFinder.ibiza_exercises_cache_name(@user.ibiza_id, @software.updated_at)).present?
  end
end

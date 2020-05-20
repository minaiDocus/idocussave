# Delivery's xml for a specific pre assignment delivery
class PreAssignmentDeliveryXmlBuilder

  def self.execute
    PreAssignmentDelivery.pending.order(id: :asc).each do |delivery|
      PreAssignmentDeliveryXmlBuilder.new(delivery).execute
    end
  end

  def initialize(delivery)
    @delivery    = delivery

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
      response = IbizaAPI::Utils.to_import_xml(ibiza_exercise, @preseizures, @software)

      if response[:data_count] > 0
        save_data_to_storage response[:data_built]

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

  def build_for_exact_online
    @delivery.building_data
    response = ExactOnlineDataBuilder.new(@delivery).execute

    if response[:data_built]
      save_data_to_storage response[:data]

      @delivery.data_built
    else
      building_failed response[:error_messages]
    end
  end

  private

  def save_data_to_storage(data_built)
    if data_built.present?
      Dir.mktmpdir do |dir|
        extension = 'txt'
        extension = 'xml' if @delivery.deliver_to == 'ibiza'
        file_name = @delivery.pack_name.tr('% ', '_')
        file_path = "#{dir}/#{file_name}_#{@delivery.id}.#{extension}"

        File.open file_path, 'w' do |f|
          f.write(data_built.to_s)
        end

        @delivery.cloud_content_object.attach(File.open(file_path), "#{file_name}_#{@delivery.id}.#{extension}") if @delivery.save
      end
    end
  end

  def building_success(data_count)
    if data_count != @preseizures.size
      @delivery.error_message = "#{@preseizures.size - data_count} preseizure(s) already sent"
      @delivery.save
    end

    @delivery.data_built
  end

  def building_failed(error_message)
    @delivery.error_message = error_message
    @delivery.save
    @delivery.error

    time = Time.now

    @preseizures.each do |preseizure|
      preseizure.delivery_tried_at = time
      preseizure.is_locked         = false
      preseizure.save
      preseizure.set_delivery_message_for(@delivery.deliver_to, error_message) if !preseizure.get_delivery_message_of('ibiza').match(/already sent/i)
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

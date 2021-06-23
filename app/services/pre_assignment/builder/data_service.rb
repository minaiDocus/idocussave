class PreAssignment::Builder::DataService
  def initialize(delivery)
    @delivery    = delivery
    @user        = @delivery.user
    @report      = @delivery.report
    @preseizures = @delivery.preseizures
  end

  def run
    execute
  end

  private

  def execute; end

  def save_data_to_storage(data_built, extension)
    if data_built.present?
      CustomUtils.mktmpdir('preseizure_builder') do |dir|
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
    @delivery.error_message = '' unless @delivery.error_message.to_s.match(/limit pending reached/)
    @delivery.error_message = "#{@preseizures.size - data_count} preseizure(s) already sent" if data_count != @preseizures.size
    @delivery.save

    @delivery.data_built
  end

  def building_failed(error_message="can t open connection.")
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

    false
  end
end
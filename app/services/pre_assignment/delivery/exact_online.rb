class PreAssignment::Delivery::ExactOnline < PreAssignment::Delivery::DataService
  def self.execute(delivery)
    new(delivery).run
  end

  def initialize(delivery)
    super

    @software = @delivery.user.exact_online
  end

  private

  def execute
    @delivery.sending

    begin
      response = @delivery.data_to_deliver.present? ? ExactOnlineLib::Data.new(@user).send_pre_assignment(@delivery.data_to_deliver) : ExactOnlineLib::Data.new(@user).send_pre_assignment(File.read(@delivery.cloud_content_object.path))

      if response[:error].present?
        handle_delivery_error(response[:error])
      else
        handle_delivery_success
      end
    rescue => e
      log_document = {
        subject: "[PreAssignment::Delivery::ExactOnline] active storage can't read file #{e;message}",
        name: "PreAssignment::Delivery::ForExactOnline",
        error_group: "[pre-assignment-delivery-forexactonline] active storage can't read file",
        erreur_type: "Active Storage, can't read file",
        date_erreur: Time.now.strftime('%Y-%M-%d %H:%M:%S'),
        more_information: {
          delivery: @delivery.inspect,
          error: e.to_s
        }
      }

      ErrorScriptMailer.error_notification(log_document).deliver

      if pending_message == 'limit pending reached'
        handle_delivery_error pending_message
      else
        @delivery.update(state: 'pending', error_message: pending_message )
      end
    end

    @delivery.sent?
  end
end
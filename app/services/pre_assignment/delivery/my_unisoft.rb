class PreAssignment::Delivery::MyUnisoft < PreAssignment::Delivery::DataService
  def self.execute(delivery)
    new(delivery).run
  end

  def initialize(delivery)
    super
  end

  private

  def execute
    @delivery.sending

    begin
      send_data = MyUnisoftLib::DataSender.new(@user)
      response  = send_data.execute(@delivery.cloud_content_object.path)

      if response[:error].present?
        handle_delivery_error(response[:error])
      else
        handle_delivery_success
      end
    rescue => e
      log_document = {
        name: "PreAssignment::Delivery::my_unisoft",
        error_group: "[pre-assignment-delivery-my_unisoft] active storage can't read file",
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
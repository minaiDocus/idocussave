class PreAssignment::Delivery::Ibiza < PreAssignment::Delivery::DataService
  RETRYABLE_ERRORS = ['The fog is not checked', 'La connexion sous-jacente a été', 'An error occured', "can t open connection", "can not establish connection"]

  def self.retry_delivery(delivery_id)
    delivery = PreAssignmentDelivery.find delivery_id

    delivery.update(state: 'pending', error_message: 'retry sending') if delivery.state == 'error'
  end

	def self.execute(delivery)
    new(delivery).run
  end

  def initialize(delivery)
    super

    @software = @delivery.organization.ibiza
  end

  private

  def execute
    @delivery.sending

    ibiza_client.request.clear

    begin
      if @delivery.cloud_content_object.path.present?
        ibiza_client.company(@user.try(:ibiza).try(:ibiza_id)).entries!(File.read(@delivery.cloud_content_object.path))
      else
        ibiza_client.company(@user.try(:ibiza).try(:ibiza_id)).entries!(@delivery.data_to_deliver)
      end

      if ibiza_client.response.success?
        handle_delivery_success
      else
        error_message = ibiza_client.response.message.to_s.presence
        previous_error = @delivery.error_message

        is_retryable_error = false
        RETRYABLE_ERRORS.each do |c_error|
          is_retryable_error = true if !is_retryable_error && error_message.match(c_error)
        end

        handle_delivery_error error_message || ibiza_client.response.status.to_s

        if is_retryable_error && previous_error != 'retry sending'
          PreAssignment::Delivery::Ibiza.delay_for(1.hours, queue: :low).retry_delivery(@delivery.id)
        else
          retry_delivery = true

          ['Le journal est inconnu'].each do |message|
            retry_delivery = false if ibiza_client.response.message.to_s.match /#{message}/
          end

          if retry_delivery && @preseizures.size > 1
            @preseizures.each do |preseizure|
              deliveries = PreAssignment::CreateDelivery.new(preseizure, ['ibiza'], is_auto: false, verify: true).execute
              deliveries.first.update_attribute(:is_auto, @delivery.is_auto) if deliveries.present?
            end
          end
        end
      end
    rescue => e
      log_document = {
        subject: "[PreAssignment::Delivery::Ibiza] active storage can't read file #{e.try(:message)}",
        name: "PreAssignment::Delivery::ForIbiza",
        error_group: "[pre-assignment-delivery-foribiza] active storage can't read file",
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
        @delivery.update(state: 'pending', error_message: pending_message)
      end
    end

    @delivery.sent?
  end

  def ibiza_client
    @ibiza_client ||= IbizaLib::Api::Client.new(@delivery.ibiza_access_token, @software.specific_url_options, IbizaLib::ClientCallback.new(@software, @delivery.ibiza_access_token))
  end
end
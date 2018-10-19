# -*- encoding : UTF-8 -*-
class PreAssignmentDeliveryService
  @@processed_at = nil
  @@notified_at = Time.now

  class << self
    def execute(notify_now=false)
      PreAssignmentDelivery.data_built.order(id: :asc).each do |delivery|
        PreAssignmentDeliveryService.new(delivery).execute
        notify if @@notified_at <= 15.minutes.ago

        @@processed_at = Time.now
      end
      if notify_now || @@notified_at <= 15.minutes.ago || (@@processed_at && @@processed_at <= 1.minute.ago)
        notify

        @@processed_at = nil
      end
    end

    def notify
      deliveries = PreAssignmentDelivery.not_notified.order(id: :asc)
      if deliveries.size > 0
        ##TODO change Settings : notify_ibiza_deliveries_to to global deliveries to
        addresses = Array(Settings.first.notify_ibiza_deliveries_to)

        if addresses.size > 0
          ##TODO change IbizaMailer class to global DeliveriesMailer class
          IbizaMailer.notify_deliveries(deliveries, addresses).deliver

          deliveries.update_all(is_notified: true, notified_at: Time.now)
        else
          deliveries.unset(:is_to_notify)
        end
        @@notified_at = Time.now
      end
    end
  end

  attr_accessor :delivery, :software, :preseizures, :report, :user

  def initialize(delivery)
    @delivery    = delivery
    @software    = @delivery.deliver_to == 'ibiza' ? @delivery.organization.ibiza : @delivery.organization.exact_online
    @preseizures = @delivery.preseizures
    @report      = @delivery.report
    @user        = @delivery.user
  end


  def execute
    case @delivery.deliver_to
      when 'ibiza'
        result = send_to_ibiza
      when 'exact_online'
        result = send_to_exact_online
      else
        result = false
    end

    notify

    result
  end

  private

  def exact_online_client
    ##TODO
  end

  def ibiza_client
    @ibiza_client ||= IbizaAPI::Client.new(@delivery.ibiza_access_token, IbizaClientCallback.new(@software, @delivery.ibiza_access_token))
  end

  def exact_online
    @exact_online ||= @user.organization.exact_online
  end

  def send_to_ibiza
    @delivery.sending

    ibiza_client.request.clear
    ibiza_client.company(@user.ibiza_id).entries!(@delivery.data_to_deliver)

    if ibiza_client.response.success?
      @delivery.sent

      time = Time.now

      @preseizures.each do |preseizure|
        preseizure.delivery_tried_at = time
        preseizure.is_locked         = false
        preseizure.save
        preseizure.delivered_to('ibiza')
        preseizure.set_delivery_message_for('ibiza', '')
      end

      @report.delivery_tried_at = time
      @report.is_locked         = false
      @report.save
      @report.delivered_to('ibiza') if @delivery.preseizures.not_ibiza_delivered.count == 0
      @report.set_delivery_message_for('ibiza', '')
    else
      @delivery.update_attribute(:error_message, ibiza_client.response.message.to_s)
      @delivery.error

      time = Time.now

      @preseizures.each do |preseizure|
        preseizure.delivery_tried_at = time
        preseizure.is_locked         = false
        preseizure.save
        preseizure.set_delivery_message_for('ibiza', ibiza_client.response.message.to_s)
      end

      @report.delivery_tried_at = time
      @report.is_locked         = false
      @report.save
      @report.set_delivery_message_for('ibiza', ibiza_client.response.message.to_s)

      retry_delivery = true

      ['Le journal est inconnu'].each do |message|
        retry_delivery = false if ibiza_client.response.message.to_s.match /#{message}/
      end

      if retry_delivery && @preseizures.size > 1
        @preseizures.each do |preseizure|
          deliveries = CreatePreAssignmentDeliveryService.new(preseizure, ['ibiza'], is_auto: false, verify: true).execute
          deliveries.first.update_attribute(:is_auto, @delivery.is_auto) if deliveries.present?
        end
      end

      NotifyPreAssignmentDeliveryFailure.new(@delivery).execute
    end

    @delivery.sent?
  end

  def send_to_exact_online
    @delivery.sending

    exact_online.refresh_session_if_needed
    exact_online.clear_client

    # response = exact_online.client.send_preseizure(@delivery.data_to_deliver)

    ##TODO

  end

  def notify?
    ##TODO Settings : notify_on_ibiza_delivery to global
    Settings.first.notify_on_ibiza_delivery == 'yes'
  end


  def notify_error?
    ##TODO Settings : notify_on_ibiza_delivery to global
    Settings.first.notify_on_ibiza_delivery == 'error'
  end


  def notify
    if notify? || (notify_error? && @delivery.error?)
      @delivery.update(is_to_notify: true)
    end
  end
end

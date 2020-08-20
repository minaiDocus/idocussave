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
          deliveries.group_by(&:deliver_to).each do |to, group_deliveries|
            PreAssignmentDeliveryMailer.notify_deliveries(group_deliveries, addresses).deliver
          end

          deliveries.update_all(is_notified: true, notified_at: Time.now)
        else
          deliveries.unset(:is_to_notify)
        end
        @@notified_at = Time.now
      end
    end

    def retry_to_deliver(id_delivery, count_day)
      delivery = PreAssignmentDelivery.find id_delivery
      if count_day <= 2
        PreAssignmentDeliveryService.new(delivery, count_day).execute
      else
        delivery.update(state: 'error')
      end
    end
  end

  attr_accessor :delivery, :software, :preseizures, :report, :user

  def initialize(delivery, count_day=0)
    @delivery    = delivery
    @software    = @delivery.deliver_to == 'ibiza' ? @delivery.organization.ibiza : @delivery.user.exact_online
    @preseizures = @delivery.preseizures
    @report      = @delivery.report
    @user        = @delivery.user
    @count_day   = count_day
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

  def ibiza_client
    @ibiza_client ||= IbizaAPI::Client.new(@delivery.ibiza_access_token, IbizaClientCallback.new(@software, @delivery.ibiza_access_token))
  end

  def send_to_ibiza
    @delivery.sending

    ibiza_client.request.clear

    begin
      if @delivery.cloud_content_object.path.present?
        ibiza_client.company(@user.ibiza_id).entries!(File.read(@delivery.cloud_content_object.path))
      else
        ibiza_client.company(@user.ibiza_id).entries!(@delivery.data_to_deliver)
      end

      if ibiza_client.response.success?
        handle_delivery_success
      else
        handle_delivery_error ibiza_client.response.message.to_s.presence || ibiza_client.response.status.to_s

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
      end
    rescue => e
      log_document = {
        name: "PreAssignmentDeliveryService",
        error_group: "[pre-assignment-delivery-service] active storage can't read file",
        erreur_type: "Active Storage, can't read file",
        date_erreur: Time.now.strftime('%Y-%M-%d %H:%M:%S'),
        more_information: {
          delivery: @delivery.inspect,
          error: e.to_s
        }
      }
      ErrorScriptMailer.error_notification(log_document).deliver

      PreAssignmentDeliveryService.delay_for(24.hours).retry_to_deliver(@delivery.id, (@count_day+1)) if @count_day <= 2      

      # @delivery.update(state: 'pending')
    end

    @delivery.sent?
  end

  def send_to_exact_online
    @delivery.sending

    begin
      response = @delivery.data_to_deliver.present? ? ExactOnlineData.new(@user).send_pre_assignment(@delivery.data_to_deliver) : ExactOnlineData.new(@user).send_pre_assignment(File.read(@delivery.cloud_content_object.path))

      if response[:error].present?
        handle_delivery_error(response[:error])
      else
        handle_delivery_success
      end
    rescue => e
      log_document = {
        name: "PreAssignmentDeliveryService",
        error_group: "[pre-assignment-delivery-service] active storage can't read file",
        erreur_type: "Active Storage, can't read file",
        date_erreur: Time.now.strftime('%Y-%M-%d %H:%M:%S'),
        more_information: {
          delivery: @delivery.inspect,
          error: e.to_s
        }
      }
      ErrorScriptMailer.error_notification(log_document).deliver

      @delivery.update(state: 'data_built')
    end

    @delivery.sent?
  end

  def handle_delivery_error(error_message)
    @delivery.update_attribute(:error_message, error_message.to_s)
    @delivery.error

    time = Time.now

    @preseizures.each do |preseizure|
      preseizure.delivery_tried_at = time
      preseizure.is_locked         = false
      preseizure.save
      preseizure.set_delivery_message_for(@delivery.deliver_to, error_message.to_s) if !preseizure.get_delivery_message_of('ibiza').match(/already sent/i)
    end

    @report.delivery_tried_at = time
    @report.is_locked         = false
    @report.save
    @report.set_delivery_message_for(@delivery.deliver_to, error_message.to_s)

    NotifyPreAssignmentDeliveryFailure.new(@delivery).execute
  end

  def handle_delivery_success
    @delivery.sent

    time = Time.now

    @preseizures.each do |preseizure|
      preseizure.delivery_tried_at = time
      preseizure.is_locked         = false
      preseizure.save
      preseizure.delivered_to(@delivery.deliver_to)
      preseizure.set_delivery_message_for(@delivery.deliver_to, '') if !preseizure.get_delivery_message_of('ibiza').match(/already sent/i)
    end

    @report.delivery_tried_at = time
    @report.is_locked         = false
    @report.save

    case @delivery.deliver_to
      when 'ibiza'
        @report.delivered_to('ibiza') if @report.preseizures.reload.not_deleted.not_ibiza_delivered.count == 0
      when 'exact_online'
        @report.delivered_to('exact_online') if @report.preseizures.reload.not_deleted.not_exact_online_delivered.count == 0
    end

    @report.set_delivery_message_for(@delivery.deliver_to, '')
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


# -*- encoding : UTF-8 -*-
class PreAssignmentDeliveryService
  @@processed_at = nil
  @@notified_at = Time.now

  class << self
    def execute(notify_now=false)
      PreAssignmentDelivery.xml_built.order(id: :asc).each do |delivery|
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
        addresses = Array(Settings.first.notify_ibiza_deliveries_to)

        if addresses.size > 0
          IbizaMailer.notify_deliveries(deliveries, addresses).deliver

          deliveries.update_all(is_notified: true, notified_at: Time.now)
        else
          deliveries.unset(:is_to_notify)
        end
        @@notified_at = Time.now
      end
    end
  end

  attr_accessor :delivery, :ibiza, :preseizures, :report, :user

  def initialize(delivery)
    @delivery    = delivery
    @ibiza       = @delivery.organization.ibiza
    @preseizures = @delivery.preseizures
    @report      = @delivery.report
    @user        = @delivery.user
  end


  def execute
    result = send

    notify

    result
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
    @exercise ||= FindExercise.new(@user, grouped_date, @ibiza).execute
  end


  def is_exercises_present?
    Rails.cache.read(FindExercise.ibiza_exercises_cache_name(@user.ibiza_id, @ibiza.updated_at)).present?
  end


  def client
    @client ||= IbizaAPI::Client.new(@delivery.ibiza_access_token, IbizaClientCallback.new(@ibiza, @delivery.ibiza_access_token))
  end


  def send
    @delivery.sending

    client.request.clear
    client.company(@user.ibiza_id).entries!(@delivery.xml_data)

    if client.response.success?
      @delivery.sent

      time = Time.now

      @preseizures.each do |preseizure|
        preseizure.is_delivered      = true
        preseizure.delivery_tried_at = time
        preseizure.delivery_message  = ''
        preseizure.is_locked         = false
        preseizure.save
      end

      @report.is_delivered      = @report.preseizures.not_delivered.count == 0
      @report.delivery_tried_at = time
      @report.delivery_message  = ''
      @report.is_locked         = false
      @report.save
    else
      @delivery.update_attribute(:error_message, client.response.message.to_s)
      @delivery.error

      time = Time.now

      @preseizures.each do |preseizure|
        preseizure.delivery_tried_at = time
        preseizure.delivery_message  = client.response.message.to_s
        preseizure.is_locked         = false
        preseizure.save
      end

      @report.delivery_tried_at = time
      @report.delivery_message  = client.response.message.to_s
      @report.is_locked         = false
      @report.save

      retry_delivery = true

      ['Le journal est inconnu', 'Le compte est fermé', 'Le compte est absent'].each do |message|
        retry_delivery = false if client.response.message.to_s.match /#{message}/
      end

      if retry_delivery && @preseizures.size > 1
        @preseizures.each do |preseizure|
          deliveries = CreatePreAssignmentDeliveryService.new(preseizure, is_auto: false, verify: true).execute
          deliveries.first.update_attribute(:is_auto, @delivery.is_auto) if deliveries.present?
        end
      end

      NotifyPreAssignmentDeliveryFailure.new(@delivery).execute
    end

    @delivery.sent?
  end


  def notify?
    Settings.first.notify_on_ibiza_delivery == 'yes'
  end


  def notify_error?
    Settings.first.notify_on_ibiza_delivery == 'error'
  end


  def notify
    if notify? || (notify_error? && @delivery.error?)
      @delivery.update(is_to_notify: true)
    end
  end
end

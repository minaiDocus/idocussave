# -*- encoding : UTF-8 -*-
class PreAssignmentDeliveryService
  class << self
    def execute
      PreAssignmentDelivery.pending.asc(:number).each do |delivery|
        PreAssignmentDeliveryService.new(delivery).execute
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
    result = send if build_xml
    notify
    result
  end

  def period
    DocumentTools.to_period(@report.name)
  end

  def exercise
    @exercise ||= ExerciceService.find(@user, period, false)
  end

  def build_xml
    @delivery.building_xml
    if exercise
      @delivery.xml_data = IbizaAPI::Utils.to_import_xml(exercise, @preseizures, @ibiza.description, @ibiza.description_separator, @ibiza.piece_name_format, @ibiza.piece_name_format_sep)
      @delivery.exercise = {
        start_date: exercise.start_date.to_time,
        end_date:   exercise.end_date.to_time,
        is_closed:  exercise.is_closed
      }
      @delivery.save
      @delivery.xml_built
    else
      if client.response.success?
        @delivery.error_message = @report.delivery_message = "L'exercice correspondant n'est pas défini dans Ibiza."
      else
        @delivery.error_message = @report.delivery_message = client.response.message
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

      false
    end
  end

  def client
    @ibiza.client
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
      @delivery.update_attribute(:error_message, client.response.message)
      @delivery.error

      time = Time.now
      @preseizures.each do |preseizure|
        preseizure.delivery_tried_at = time
        preseizure.delivery_message  = client.response.message
        preseizure.is_locked         = false
        preseizure.save
      end
      @report.delivery_tried_at = time
      @report.delivery_message  = client.response.message
      @report.is_locked         = false
      @report.save

      if @preseizures.size > 1
        @preseizures.each do |preseizure|
          delivery = CreatePreAssignmentDeliveryService.new(preseizure, false).execute
          delivery.update_attribute(:is_auto, @delivery.is_auto)
        end
      end
    end

    @delivery.sent?
  end

  def notify?
    Settings.notify_on_ibiza_delivery == 'yes' && addresses.size > 0
  end

  def notify_error?
    Settings.notify_on_ibiza_delivery == 'error' && addresses.size > 0
  end

private

  def object_to_notify
    @preseizures.size > 1 ? @report : @preseizures.first
  end

  def notify
    if notify? || (notify_error? && @delivery.error?)
      IbizaMailer.notify_delivery(@delivery, addresses, @ibiza, object_to_notify).deliver
    end
  end

  def addresses
    Array(Settings.notify_ibiza_deliveries_to)
  end
end

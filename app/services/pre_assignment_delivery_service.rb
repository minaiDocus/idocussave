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
    send if build_xml
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
      false
    end
  end

  def client
    @ibiza.client
  end

  def send
    @delivery.sending
    preseizure_ids = @preseizures.map(&:id)
    id = @user.ibiza_id
    client.request.clear

    client.company(id).entries!(@delivery.xml_data)
    if client.response.success?
      Pack::Report::Preseizure.where(:_id.in => preseizure_ids).update_all(is_delivered: true)
      @report.delivery_message = ''
      @delivery.sent
    else
      @delivery.error_message = @report.delivery_message = client.response.message
      if @preseizures.size > 1
        @preseizures.each do |preseizure|
          delivery = CreatePreAssignmentDeliveryService.new(preseizure, false, true).execute
          delivery.update_attribute(:is_auto, @delivery.is_auto)
        end
      end
      @delivery.error
    end

    @report.update_attributes(is_delivered: true) if @report.preseizures.not_delivered.count == 0
    @report.update_attributes(delivery_tried_at: Time.now, is_locked: false)
    Pack::Report::Preseizure.where(:_id.in => preseizure_ids).update_all(is_locked: false, delivery_tried_at: Time.now, delivery_message: report.delivery_message)

    notify
    @delivery.sent?
  end

  def notify?
    IbizaAPI::Config::NOTIFY_ON_DELIVERY == :yes
  end

  def notify_error?
    IbizaAPI::Config::NOTIFY_ON_DELIVERY == :error
  end

private

  def object_to_notify
    @preseizures.size > 1 ? @report : @preseizures.first
  end

  def notify
    if notify? || (notify_error? && @delivery.error?)
      IbizaMailer.notify_delivery(@ibiza, object_to_notify, @delivery.xml_data).deliver
    end
  end
end

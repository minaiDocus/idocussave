# -*- encoding : UTF-8 -*-
class PreAssignment::Delivery::DataService
  @@notified_at ||= Time.now

  class << self
    def notify_deliveries
      UniqueJobs.for 'PreAssignmentDeliveryNotifier' do
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
    end
  end

  attr_accessor :delivery, :software_name, :preseizures, :report, :user

  def initialize(delivery)
    @delivery       = delivery
    @software_name  = @delivery.deliver_to
    @preseizures    = @delivery.preseizures
    @report         = @delivery.report
    @user           = @delivery.user
  end

  def run
    result = execute
    notify

    PreAssignment::Delivery::DataService.delay.notify_deliveries if @@notified_at <= 10.minutes.ago
    result
  end

  private

  def execute; end

  def handle_delivery_error(error_message="can t open connection")
    @delivery.update_attribute(:error_message, error_message.to_s)
    @delivery.error

    time = Time.now

    @preseizures.each do |preseizure|
      preseizure.delivery_tried_at = time
      preseizure.is_locked         = false
      preseizure.save
      preseizure.set_delivery_message_for(@software_name, error_message.to_s) if !preseizure.get_delivery_message_of('ibiza').match(/already sent/i)
    end

    @report.delivery_tried_at = time
    @report.is_locked         = false
    @report.save
    @report.set_delivery_message_for(@software_name, error_message.to_s)

    Notifications::PreAssignments.new({delivery: @delivery, user: @delivery.user}).notify_pre_assignment_delivery_failure
  end

  def handle_delivery_success
    @delivery.sent

    time = Time.now

    @preseizures.each do |preseizure|
      preseizure.delivery_tried_at = time
      preseizure.is_locked         = false
      preseizure.save
      preseizure.delivered_to(@software_name)
      preseizure.set_delivery_message_for(@software_name, '') if !preseizure.get_delivery_message_of('ibiza').match(/already sent/i)
    end

    @report.delivery_tried_at = time
    @report.is_locked         = false
    @report.save

    @report.delivered_to(@software_name) if @report.preseizures.reload.not_deleted.not_delivered(@software_name).count == 0

    @report.set_delivery_message_for(@software_name, '')
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
    @delivery.update(is_to_notify: true) if notify? || (notify_error? && @delivery.error?)
  end

  def pending_message
    return @pending_message if @pending_message.present?

    @pending_message = @delivery.error_message

    if @pending_message.to_s.match(/_#_/)
      limit_attempt = @pending_message.split("_#_").last.to_i

      if limit_attempt < 3
        @pending_message = "limit_pending_#_#{limit_attempt + 1}"
      else
        @pending_message = "limit pending reached"
      end
    elsif !@pending_message.to_s.match(/limit pending reached/)
      @pending_message = "limit_pending_#_1"
    end

    @pending_message
  end
end
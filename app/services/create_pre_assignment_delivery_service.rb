# -*- encoding : UTF-8 -*-
class CreatePreAssignmentDeliveryService
  attr_reader :deliveries

  def initialize(preseizures, options = {})
    @preseizures = Array(preseizures)
    @report      = @preseizures.first.try(:report)
    @is_auto     = options[:is_auto] || false
    @verify      = options[:verify]  || false
    @deliveries  = []
  end

  def valid?
    ibiza.try(:configured?) &&
      (!@is_auto || @report.user.options.auto_deliver?) &&
      @report.user.try(:ibiza_id).present? &&
      !@preseizures.select(&:is_locked).first
  end

  def execute
    if valid?
      @to_deliver_preseizures = @verify ? IbizaPreseizureFinder.not_delivered(@preseizures) : @preseizures

      return false if @to_deliver_preseizures.empty?

      ids                   = @to_deliver_preseizures.map(&:id)
      already_delivered_ids = @preseizures.map(&:id) - ids

      Pack::Report::Preseizure.where(id: ids).update_all(is_locked: true)
      Pack::Report::Preseizure.where(id: already_delivered_ids).update_all(is_delivered: true) if already_delivered_ids.any?

      grouped_preseizures = {}
      if @report.user.options.pre_assignment_date_computed?
        date = DocumentTools.to_period(@report.name)
        grouped_preseizures = { [date, nil] => @to_deliver_preseizures }
      else
        grouped_preseizures = @to_deliver_preseizures.group_by do |preseizure|
          date = preseizure.date.try(:beginning_of_month).try(:to_date) || DocumentTools.to_period(@report.name)
          [date, nil]
        end
      end

      if ibiza.two_channel_delivery?
        groups = {}
        grouped_preseizures.each do |(date, channel), preseizures|
          bank_preseizures = preseizures.select(&:operation)
          normal_preseizures = preseizures - bank_preseizures
          groups = groups.merge({ [date, true] => bank_preseizures })   if bank_preseizures.size > 0
          groups = groups.merge({ [date, nil]  => normal_preseizures }) if normal_preseizures.size > 0
        end
        grouped_preseizures = groups
      end

      grouped_preseizures.each do |(date, channel), preseizures|
        delivery = PreAssignmentDelivery.new
        delivery.report       = @report
        delivery.user         = @report.user
        delivery.organization = @report.organization
        delivery.pack_name    = @report.name
        delivery.ibiza_id     = @report.user.ibiza_id
        delivery.is_auto      = @is_auto
        delivery.grouped_date = date
        delivery.total_item   = preseizures.size
        delivery.preseizures  = preseizures
        if delivery.save
          preseizures.first.save if preseizures.size == 1

          PreAssignmentDeliveryXmlBuilderWorker.perform_async(delivery.id)

          @deliveries << delivery
        end
      end

      @report.update_attribute(:is_locked, (@report.preseizures(true).not_locked.count == 0))
      @deliveries
    else
      false
    end
  end

private

  def ibiza
    @report.try(:organization).try(:ibiza)
  end
end

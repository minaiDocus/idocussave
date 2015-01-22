# -*- encoding : UTF-8 -*-
class CreatePreAssignmentDeliveryService
  attr_reader :deliveries

  def initialize(preseizures, is_auto=false)
    @preseizures = Array(preseizures)
    @report      = @preseizures.first.try(:report)
    @is_auto     = is_auto
    @deliveries  = []
  end

  def valid?
    @report.try(:organization).try(:ibiza).try(:is_configured?) &&
      (!@is_auto || @report.organization.ibiza.is_auto_deliver) &&
      @report.user.try(:ibiza_id).present? &&
      !@preseizures.select(&:is_locked).first
  end

  def execute
    if valid?
      ids = @preseizures.map(&:id)
      Pack::Report::Preseizure.where(:_id.in => ids).update_all(is_locked: true)

      grouped_preseizures = []
      if @report.user.try(:is_computed_date_used)
        grouped_preseizures = [@preseizures]
      else
        grouped_preseizures = @preseizures.group_by do |preseizure|
          preseizure.date.beginning_of_month.to_date
        end
      end

      grouped_preseizures.each do |date, preseizures|
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
          delivery.reload # Relation N-N buggé
          @deliveries << delivery
        end
      end

      @report.update_attribute(:is_locked, (@report.preseizures.not_locked.count == 0))
      @deliveries
    else
      false
    end
  end
end

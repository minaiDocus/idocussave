# -*- encoding : UTF-8 -*-
class CreatePreAssignmentDeliveryService
  attr_reader :delivery

  def initialize(preseizures, is_auto=false)
    @preseizures = Array(preseizures)
    @report      = @preseizures.first.try(:report)
    @is_auto     = is_auto
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

      @delivery = PreAssignmentDelivery.new
      @delivery.report       = @report
      @delivery.user         = @report.user
      @delivery.organization = @report.organization
      @delivery.pack_name    = @report.name
      @delivery.is_auto      = @is_auto
      @delivery.total_item   = @preseizures.size
      @delivery.ibiza_id     = @report.user.ibiza_id
      @delivery.preseizures  = @preseizures
      @delivery.save
      # Relation N-N buggé
      @delivery.reload
      @report.update_attribute(:is_locked, (@report.preseizures.not_locked.count == 0))
      @delivery if @delivery.persisted?
    else
      false
    end
  end
end

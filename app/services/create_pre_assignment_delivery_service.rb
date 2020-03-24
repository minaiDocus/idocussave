# -*- encoding : UTF-8 -*-
## Sending simultaniously to ibiza and exact_online for an user is not supported for now
class CreatePreAssignmentDeliveryService
  attr_reader :deliveries

  def initialize(preseizures, deliver_to=['ibiza'], options = {})
    @preseizures = Array(preseizures)
    @deliver_to  = Array(deliver_to)
    @report      = @preseizures.first.try(:report)
    @is_auto     = options[:is_auto] || false
    @deliveries  = []
  end

  def valid_ibiza?
    @preseizures.any? && ibiza.try(:configured?) &&
    (!@is_auto || @report.user.softwares.ibiza_auto_deliver?) &&
    @report.user.try(:ibiza_id).present? && @report.user.uses_ibiza? &&
    !@preseizures.select(&:is_locked).first
    #preseizures locked test stops sending to exact_online => to review if simultanious sending needed (actually not supported)
  end

  def valid_exact_online?
    @preseizures.any? && @report.try(:organization).try(:is_exact_online_used) &&
    (!@is_auto || @report.user.softwares.exact_online_auto_deliver?) &&
    @report.user.exact_online.try(:fully_configured?) && @report.user.uses_exact_online? &&
    !@preseizures.select(&:is_locked).first
  end

  def execute
    ibiza_deliveries        = @deliver_to.include?('ibiza') ? deliver_to_ibiza : []
    exact_online_deliveries = @deliver_to.include?('exact_online') ? deliver_to_exact_online : []

    @deliveries = ibiza_deliveries + exact_online_deliveries
    @report.update_attribute(:is_locked, (@report.preseizures.reload.not_deleted.not_locked.count == 0)) if @preseizures.any?

    if @deliveries.any?
      @deliveries
    else
      false
    end
  end

  def deliver_to_ibiza
    if valid_ibiza?
      deliveries = []

      @preseizures.each do |preseizure|
        @preseizure = preseizure

        preseizure.update(is_locked: true)

        grouped_preseizures = date_preseizure

        if ibiza.two_channel_delivery?
          groups = {}
          grouped_preseizures.each do |(date, channel), preseizures|
            bank_preseizures   = preseizures.select(&:operation)
            normal_preseizures = preseizures - bank_preseizures
            groups = groups.merge({ [date, true] => bank_preseizures })   if bank_preseizures.size > 0
            groups = groups.merge({ [date, nil]  => normal_preseizures }) if normal_preseizures.size > 0
          end
          grouped_preseizures = groups
        end

        grouped_preseizures.each do |(date, channel), preseizures|
          delivery = PreAssignmentDelivery.new
          delivery.report       = @report
          delivery.deliver_to   = 'ibiza'
          delivery.user         = @report.user
          delivery.organization = @report.organization
          delivery.pack_name    = @report.name
          delivery.software_id  = @report.user.ibiza_id
          delivery.is_auto      = @is_auto
          delivery.grouped_date = date
          delivery.total_item   = preseizures.size
          delivery.preseizures  = preseizures
          if delivery.save
            preseizures.first.save if preseizures.size == 1

            deliveries << delivery
          end
        end
      end

      deliveries
    else
      []
    end
  end

  def deliver_to_exact_online
    if valid_exact_online?
      deliveries = []

      @preseizures.each do |preseizure|
        @preseizure = preseizure

        preseizure.update(is_locked: true)

        date_preseizure.each do |(date, channel), preseizures|
          delivery = PreAssignmentDelivery.new
          delivery.report       = @report
          delivery.deliver_to   = 'exact_online'
          delivery.user         = @report.user
          delivery.organization = @report.organization
          delivery.pack_name    = @report.name
          delivery.software_id  = @report.user.exact_online.client_id
          delivery.is_auto      = @is_auto
          delivery.grouped_date = date
          delivery.total_item   = preseizures.size
          delivery.preseizures  = preseizures
          if delivery.save
            preseizures.first.save if preseizures.size == 1

            deliveries << delivery
          end
        end
      end

      deliveries
    else
      []
    end
  end

private

  def date_preseizure
    if @report.user.options.pre_assignment_date_computed?
      date = DocumentTools.to_period(@report.name)
    else
      date = @preseizure.date.try(:beginning_of_month).try(:to_date) || DocumentTools.to_period(@report.name)
    end

    { [date, nil] => [@preseizure] }
  end

  def ibiza
    @report.try(:organization).try(:ibiza)
  end
end
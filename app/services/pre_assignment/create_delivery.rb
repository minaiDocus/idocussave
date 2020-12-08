# -*- encoding : UTF-8 -*-
## Sending simultaniously to ibiza and exact_online for an user is not supported for now
class PreAssignment::CreateDelivery
  attr_reader :deliveries

  def initialize(preseizures, deliver_to=['ibiza'], options = {})
    @preseizures = Array(preseizures)
    @deliver_to  = Array(deliver_to)
    @report      = @preseizures.first.try(:report)
    @is_auto     = options[:is_auto] || false
    @verify      = options[:verify]  || false
    @force_send  = options[:force]   || false
    @deliveries  = []
  end

  def valid_ibiza?
    @preseizures.any? && ibiza.try(:configured?) &&
    (!@is_auto || @report.user.try(:ibiza).try(:auto_deliver?)) &&
    @report.user.try(:ibiza).try(:ibiza_id?) && @report.user.uses?(:ibiza) &&
    !@preseizures.select(&:is_locked).first
    #preseizures locked test stops sending to exact_online => to review if simultanious sending needed (actually not supported)
  end

  def valid_exact_online?
    @preseizures.any? && @report.try(:organization).try(:exact_online).try(:used?) &&
    (!@is_auto || @report.user.try(:exact_online).try(:auto_deliver?)) &&
    @report.user.exact_online.try(:fully_configured?) && @report.user.uses?(:exact_online) &&
    !@preseizures.select(&:is_locked).first
  end

  def valid_my_unisoft?
    @preseizures.any? && @report.try(:organization).try(:my_unisoft).try(:used?) &&
    (
      !@is_auto ||
      (@report.user.my_unisoft.try(:auto_deliver?) ||
        (@report.user.my_unisoft.try(:auto_deliver) == -1 && @report.user.organization.my_unisoft.try(:auto_deliver?)
        )
      )
    ) && !@preseizures.select(&:is_locked).first
  end

  def execute
    ibiza_deliveries        = @deliver_to.include?('ibiza') ? deliver_to_ibiza : []
    exact_online_deliveries = @deliver_to.include?('exact_online') ? deliver_to_exact_online : []
    my_unisoft_deliveries   = @deliver_to.include?('my_unisoft') ? deliver_to_my_unisoft : []

    @deliveries = ibiza_deliveries + exact_online_deliveries + my_unisoft_deliveries
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
      ids = @preseizures.map(&:id)

      Pack::Report::Preseizure.where(id: ids).update_all(is_locked: true)

      @to_deliver_preseizures = @preseizures

      grouped_preseizures = group_preseizures

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
        delivery.deliver_to   = 'ibiza'
        delivery.user         = @report.user
        delivery.organization = @report.organization
        delivery.pack_name    = @report.name
        delivery.software_id  = @report.user.try(:ibiza).try(:ibiza_id)
        delivery.is_auto      = @is_auto
        delivery.grouped_date = date
        delivery.total_item   = preseizures.size
        delivery.preseizures  = preseizures
        delivery.error_message = 'force sending' if @force_send
        if delivery.save
          preseizures.first.save if preseizures.size == 1

          deliveries << delivery
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

      @to_deliver_preseizures = @verify ? @preseizures.select{ |p| !p.exact_online_id.present? } : @preseizures

      return [] if @to_deliver_preseizures.empty?

      ids                   = @to_deliver_preseizures.map(&:id)
      already_delivered_ids = @preseizures.map(&:id) - ids

      Pack::Report::Preseizure.where(id: ids).update_all(is_locked: true)
      Pack::Report::Preseizure.where(id: already_delivered_ids).each { |p| p.delivered_to('exact_online') } if already_delivered_ids.any?

      group_preseizures.each do |(date, channel), preseizures|
        delivery = PreAssignmentDelivery.new
        delivery.report       = @report
        delivery.deliver_to   = 'exact_online'
        delivery.user         = @report.user
        delivery.organization = @report.organization
        delivery.pack_name    = @report.name
        delivery.software_id  = @report.user.try(:exact_online).try(:client_id)
        delivery.is_auto      = @is_auto
        delivery.grouped_date = date
        delivery.total_item   = preseizures.size
        delivery.preseizures  = preseizures
        if delivery.save
          preseizures.first.save if preseizures.size == 1

          deliveries << delivery
        end
      end

      deliveries
    else
      []
    end
  end

  def deliver_to_my_unisoft
    if valid_my_unisoft?      
      deliveries = []

      @to_deliver_preseizures = @preseizures

      return [] if @to_deliver_preseizures.empty?

      ids                   = @to_deliver_preseizures.map(&:id)
      already_delivered_ids = @preseizures.map(&:id) - ids

      Pack::Report::Preseizure.where(id: ids).update_all(is_locked: true)
      Pack::Report::Preseizure.where(id: already_delivered_ids).each { |p| p.delivered_to('my_unisoft') } if already_delivered_ids.any?

      group_preseizures.each do |(date, channel), preseizures|
        delivery              = PreAssignmentDelivery.new
        delivery.report       = @report
        delivery.deliver_to   = 'my_unisoft'
        delivery.user         = @report.user
        delivery.organization = @report.organization
        delivery.pack_name    = @report.name
        delivery.software_id  = @report.user.my_unisoft.society_id
        delivery.is_auto      = @is_auto
        delivery.grouped_date = date
        delivery.total_item   = preseizures.size
        delivery.preseizures  = preseizures

        if delivery.save
          preseizures.first.save if preseizures.size == 1

          deliveries << delivery
        end
      end

      deliveries
    else
      []
    end
  end

private

  def group_preseizures
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
    grouped_preseizures
  end

  def ibiza
    @report.try(:organization).try(:ibiza)
  end
end

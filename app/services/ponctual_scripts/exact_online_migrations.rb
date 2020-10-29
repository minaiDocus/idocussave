class PonctualScripts::ExactOnlineMigrations
  class << self
    def execute
      new().execute
    end
  end

  def initialize
  end

  def execute
    p 'fill_ibiza_deliveries'
    fill_ibiza_deliveries
    p 'check_if_delivered'
    check_if_delivered
    p 'modify_delivery_message'
    modify_delivery_message
  end

  private

  def fill_ibiza_deliveries
    deliveries = PreAssignmentDelivery.all
    deliveries.update_all(deliver_to: 'ibiza')
  end

  def modify_delivery_message
    reports = Pack::Report.where.not(delivery_message: [nil, ''])
    reports.each do |a|
      next if a.delivery_message.match(/[{]"ibiza":/)

      a.delivery_message = {'ibiza': a.delivery_message}.to_json.to_s
      a.save
    end

    preseizures = Pack::Report::Preseizure.unscoped.where.not(delivery_message: [nil, ''])
    preseizures.each do |a|
      next if a.delivery_message.match(/[{]"ibiza":/)

      a.delivery_message = {'ibiza': a.delivery_message}.to_json.to_s
      a.save
    end
  end

  def check_if_delivered
    Pack::Report::Preseizure.unscoped.where(is_delivered: true).update_all(is_delivered_to: 'ibiza')

    Pack::Report.where(is_delivered: true).update_all(is_delivered_to: 'ibiza')
  end

end
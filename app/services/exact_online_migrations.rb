class ExactOnlineMigrations
  class << self
    def execute
      new().execute
    end
  end

  def initialize
  end

  def execute
    fill_ibiza_deliveries
    modify_delivery_message
    check_if_delivered
  end

  private

  def fill_ibiza_deliveries
    deliveries = PreAssignmentDelivery.all
    deliveries.update_all(deliver_to: 'ibiza')
  end

  def modify_delivery_message
    preseizures = Pack::Report::Preseizure.unscoped.where.not(delivery_message: [nil, ''])
    preseizures.each do |a|
      a.delivery_message = {'ibiza': a.delivery_message}.to_json.to_s
      a.save
    end

    reports = Pack::Report.where.not(delivery_message: [nil, ''])
    reports.each do |a|
      next if a.delivery_message.match(/[{]'ibiza'[:]/)

      a.delivery_message = {'ibiza': a.delivery_message}.to_json.to_s
      a.save
    end
  end

  def check_if_delivered
    preseizures = Pack::Report::Preseizure.unscoped.where(is_delivered: true)
    preseizures.each do |a|
      a.is_delivered_to = 'ibiza'
      a.save
    end

    reports = Pack::Report.where(is_delivered: true)
    reports.each do |a|
      next if a.delivery_message.match(/[{]'ibiza'[:]/)

      a.is_delivered_to = 'ibiza'
      a.save
    end
  end
end
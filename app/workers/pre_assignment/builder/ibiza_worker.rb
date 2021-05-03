class PreAssignment::Builder::IbizaWorker
  include Sidekiq::Worker
  sidekiq_options unique: :until_and_while_executing

  def perform
    UniqueJobs.for 'PreAssignmentBuilderIbizaWorker' do
      PreAssignmentDelivery.ibiza.pending.order(id: :asc).each do |delivery|
        sleep(5)
        next if PreAssignmentDelivery.ibiza.building_data.count >= 3 #Launch bulding data every 3 building deliveries

        PreAssignment::Builder::IbizaWorker::Launcher.delay.process(delivery.id)
      end
    end
  end

  class Launcher
    def self.process(delivery_id)
      UniqueJobs.for "PreAssignmentBuilderIbiza-#{delivery_id}" do
        delivery = PreAssignmentDelivery.find(delivery_id)
        PreAssignment::Builder::Ibiza.new(delivery).run if delivery.pending?
      end
    end
  end
end
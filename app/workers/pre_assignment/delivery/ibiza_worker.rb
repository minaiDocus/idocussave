class PreAssignment::Delivery::IbizaWorker
  include Sidekiq::Worker
  sidekiq_options retry: false, unique: :until_and_while_executing

  def perform
    UniqueJobs.for 'PreAssignmentDeliveryIbizaWorker' do
      PreAssignmentDelivery.ibiza.data_built.order(id: :asc).each do |delivery|
        sleep(5)
        next if PreAssignmentDelivery.ibiza.sending.count >= 3 #Launch sending data every 3 sending deliveries

        PreAssignment::Delivery::IbizaWorker::Launcher.delay.process(delivery.id)
      end
    end
  end

  class Launcher
    def self.process(delivery_id)
      UniqueJobs.for "PreAssignmentDeliveryIbiza-#{delivery_id}" do
        delivery = PreAssignmentDelivery.find(delivery_id)
        PreAssignment::Delivery::Ibiza.new(delivery).run if delivery.data_built?
      end
    end
  end
end
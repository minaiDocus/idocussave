class PreAssignment::Delivery::ExactOnlineWorker
  include Sidekiq::Worker
  sidekiq_options retry: false, unique: :until_and_while_executing

  def perform
    UniqueJobs.for 'PreAssignmentDeliveryExactOnlineWorker' do
      PreAssignmentDelivery.exact_online.data_built.order(id: :asc).each do |delivery|
        PreAssignment::Delivery::ExactOnlineWorker::Launcher.delay.process(delivery.id)
        sleep(5)
      end
    end
  end

  class Launcher
    def self.process(delivery_id)
      UniqueJobs.for "PreAssignmentDeliveryExactOnline-#{delivery_id}" do
        delivery = PreAssignmentDelivery.find(delivery_id)
        PreAssignment::Delivery::ExactOnline.new(delivery).run if delivery.data_built?
      end
    end
  end
end
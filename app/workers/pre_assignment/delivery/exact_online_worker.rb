class PreAssignment::Delivery::ExactOnlineWorker
  include Sidekiq::Worker
  sidekiq_options retry: false, unique: :until_and_while_executing

  def self.process(delivery_id)
    delivery = PreAssignmentDelivery.find(delivery_id)

    PreAssignment::Delivery::ExactOnline.new(delivery).run
  end

  def perform
    UniqueJobs.for 'PreAssignmentDeliveryExactOnlineWorker' do
      PreAssignmentDelivery.exact_online.data_built.order(id: :asc).each do |delivery|
        UniqueJobs.for "PreAssignmentDeliveryExactOnline-#{delivery.id}" do
          PreAssignment::Delivery::ExactOnlineWorker.delay.process(delivery.id)

          sleep(5)
        end
      end
    end
  end
end
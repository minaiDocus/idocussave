class PreAssignment::Delivery::IbizaWorker
  include Sidekiq::Worker
  sidekiq_options retry: false, unique: :until_and_while_executing

  def self.process(delivery_id)
    delivery = PreAssignmentDelivery.find(delivery_id)

    PreAssignment::Delivery::Ibiza.new(delivery).run
  end

  def perform
    UniqueJobs.for 'PreAssignmentDeliveryIbizaWorker' do
      PreAssignmentDelivery.ibiza.data_built.order(id: :asc).each do |delivery|
        UniqueJobs.for "PreAssignmentDeliveryIbiza-#{delivery.id}" do
        PreAssignment::Delivery::IbizaWorker.delay.process(delivery.id)

        sleep(5)
        end
      end
    end
  end
end
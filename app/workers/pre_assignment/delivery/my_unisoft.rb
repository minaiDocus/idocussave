class PreAssignment::Delivery::MyUnisoftWorker
  include Sidekiq::Worker
  sidekiq_options retry: false, unique: :until_and_while_executing

  def perform
    # UniqueJobs.for 'PreAssignmentDeliveryMyUnisoftWorker' do
    #   PreAssignmentDelivery.my_unisoft.data_built.order(id: :asc).each do |delivery|
    #     PreAssignment::Delivery::MyUnisoftWorker::Launcher.delay.process(delivery.id)
    #     sleep(5)
    #   end
    # end
  end

  class Launcher
    def self.process(delivery_id)
      UniqueJobs.for "PreAssignmentDeliveryMyUnisoft-#{delivery_id}" do
        delivery = PreAssignmentDelivery.find(delivery_id)
        PreAssignment::Delivery::MyUnisoft.new(delivery).run if delivery.data_built?
      end
    end
  end
end
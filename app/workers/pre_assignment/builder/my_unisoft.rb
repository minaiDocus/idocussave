class PreAssignment::Builder::MyUnisoftWorker
  include Sidekiq::Worker
  sidekiq_options unique: :until_and_while_executing

  def perform
    # UniqueJobs.for 'PreAssignmentBuilderIMyUnisoftWorker' do
    #   PreAssignmentDelivery.my_unisoft.pending.order(id: :asc).each do |delivery|
    #     PreAssignment::Builder::MyUnisoftWorker::Launcher.delay.process(delivery.id)
    #     sleep(5)
    #   end
    # end
  end

  class Launcher
    def self.process(delivery_id)
      UniqueJobs.for "PreAssignmentBuilderMyUnisoft-#{delivery_id}" do
        delivery = PreAssignmentDelivery.find(delivery_id)
        PreAssignment::Builder::MyUnisoft.new(delivery).run if delivery.pending?
      end
    end
  end
end
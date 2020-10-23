class PreAssignment::Builder::IbizaWorker
  include Sidekiq::Worker
  sidekiq_options unique: :until_and_while_executing

  def perform
    UniqueJobs.for 'PreAssignmentBuilderIbizaWorker' do
      PreAssignmentDelivery.ibiza.pending.order(id: :asc).each do |delivery|
        PreAssignment::Builder::IbizaWorker::Launcher.delay.process(delivery.id)
        sleep(5)
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
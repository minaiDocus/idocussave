class PreAssignment::Builder::ExactOnlineWorker
  include Sidekiq::Worker
  sidekiq_options unique: :until_and_while_executing

  def perform
    UniqueJobs.for 'PreAssignmentBuilderExactOnlineWorker' do
      PreAssignmentDelivery.exact_online.pending.order(id: :asc).each do |delivery|
        PreAssignment::Builder::ExactOnlineWorker::Launcher.delay.process(delivery.id)
        sleep(5)
      end
    end
  end

  class Launcher
    def self.process(delivery_id)
      UniqueJobs.for "PreAssignmentBuilderExactOnline-#{delivery_id}" do
        delivery = PreAssignmentDelivery.find(delivery_id)
        PreAssignment::Builder::ExactOnline.new(delivery).run if delivery.pending?
      end
    end
  end
end
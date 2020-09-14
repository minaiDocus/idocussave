class PreAssignment::Builder::IbizaWorker
  include Sidekiq::Worker
  sidekiq_options unique: :until_and_while_executing

  def self.process(delivery_id)
    delivery = PreAssignmentDelivery.find(delivery_id)

    PreAssignment::Builder::Ibiza.new(delivery).run
  end

  def perform
    UniqueJobs.for 'PreAssignmentBuilderIbizaWorker' do
      PreAssignmentDelivery.ibiza.pending.order(id: :asc).each do |delivery|
        UniqueJobs.for "PreAssignmentBuilderIbiza-#{delivery.id}" do
          PreAssignment::Builder::IbizaWorker.delay.process(delivery.id)

          sleep(5)
        end
      end
    end
  end
end
class PreAssignmentDeliveryXmlBuilderWorker
  include Sidekiq::Worker
  sidekiq_options unique: :until_and_while_executing

  def perform
    UniqueJobs.for 'PreAssignmentDeliveryXmlBuilder' do
      PreAssignmentDeliveryXmlBuilder.execute
    end
  end
end

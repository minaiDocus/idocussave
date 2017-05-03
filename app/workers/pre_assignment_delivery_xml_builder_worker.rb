class PreAssignmentDeliveryXmlBuilderWorker
  include Sidekiq::Worker

  def perform(delivery_id)
    PreAssignmentDeliveryXmlBuilder.new(delivery_id).execute
  end
end

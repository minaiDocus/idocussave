class PreAssignmentDeliveryXmlBuilderWorker
  include Sidekiq::Worker
  sidekiq_options unique: :until_and_while_executing

  def perform(delivery_id)
    delivery = PreAssignmentDelivery.find(delivery_id)
    $remote_lock.synchronize "PreAssignmentDeliveryXmlBuilder-#{delivery.organization.ibiza.id}", expiry: 1.hour, retries: 100 do
      PreAssignmentDeliveryXmlBuilder.new(delivery_id).execute
    end
  end
end

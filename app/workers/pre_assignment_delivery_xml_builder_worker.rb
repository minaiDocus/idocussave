class PreAssignmentDeliveryXmlBuilderWorker
  include Sidekiq::Worker
  sidekiq_options unique: :until_and_while_executing

  def perform(delivery_id)
    PreAssignmentDeliveryXmlBuilder.new(delivery_id).execute
  end
end

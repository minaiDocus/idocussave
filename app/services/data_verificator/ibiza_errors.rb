# -*- encoding : UTF-8 -*-
class DataVerificator::IbizaErrors < DataVerificator::DataVerificator
  def execute
    delivs = PreAssignmentDelivery.where('created_at >= ? AND created_at <= ? AND error_message LIKE "%La connexion sous-jacente a été%" AND state = ?', 2.days.ago, Time.now, 'error')

    messages = []

    delivs.each do |delivery|
      messages << "delivery_id: #{delivery.id}, pack_name: #{delivery.pack_name}, error_message: #{delivery.error_message.tr(',;', '--')}"
    end

    delivs = delivs.update_all(state: 'pending')

    {
      title: "IbizaErrors - #{delivs.size} delivery(s) failed",
      message: messages.join('; ')
    }
  end
end
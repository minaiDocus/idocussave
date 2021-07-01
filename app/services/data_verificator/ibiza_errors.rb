# -*- encoding : UTF-8 -*-
class DataVerificator::IbizaErrors < DataVerificator::DataVerificator
  def execute
    errors_list = PreAssignment::Delivery::Ibiza::RETRYABLE_ERRORS

    error_messages = errors_list.map do |error|
      " error_message LIKE '%#{error}%' "
    end.join(' OR ')

    delivs = PreAssignmentDelivery.where("created_at >= ? AND created_at <= ? AND state = ? AND (#{error_messages})", 5.days.ago, Time.now, 'error')

    messages = []

    delivs.each do |delivery|
      messages << "delivery_id: #{delivery.id}, pack_name: #{delivery.pack_name}, error_message: #{delivery.error_message.tr(',;', '--')}"
    end

    delivs.update_all(state: 'pending')

    {
      title: "IbizaErrors - #{delivs.size} delivery(s) failed",
      message: messages.join('; ')
    }
  end
end
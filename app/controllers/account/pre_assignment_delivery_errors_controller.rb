# -*- encoding : UTF-8 -*-
class Account::PreAssignmentDeliveryErrorsController < Account::OrganizationController
  def index
    @errors = Pack::Report::Preseizure.collection.group(
      key: [:report_id, :delivery_message],
      cond: { user_id: { '$in' => customers.map(&:id) }, delivery_message: { '$ne' => '', '$exists' => true } },
      initial: { failed_at: 0, count: 0 },
      reduce: "function(current, result) { result.count++; result.failed_at = current.delivery_tried_at; return result; }"
    ).map do |delivery|
      object = OpenStruct.new
      object.date           = delivery['failed_at'].try(:localtime)
      object.name           = Pack::Report.find(delivery['report_id']).name
      object.document_count = delivery['count'].to_i
      object.message        = delivery['delivery_message']
      object
    end.sort! do |a,b|
      b.date <=> a.date
    end
  end
end

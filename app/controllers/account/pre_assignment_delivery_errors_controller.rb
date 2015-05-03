# -*- encoding : UTF-8 -*-
class Account::PreAssignmentDeliveryErrorsController < Account::OrganizationController
  def index
    @errors = Pack::Report.failed_delivery(customers.map(&:id))
  end
end

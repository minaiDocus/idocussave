# -*- encoding : UTF-8 -*-
class Account::PreAssignmentDeliveryErrorsController < Account::OrganizationController
  # GET /account/organizations/:organization_id/pre_assignment_delivery_errors
  def index
    @errors = Pack::Report.failed_delivery(customers.map(&:id), 20)
  end
end

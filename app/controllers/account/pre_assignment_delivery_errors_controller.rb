# frozen_string_literal: true

class Account::PreAssignmentDeliveryErrorsController < Account::AccountController
  # GET /account/pre_assignment_delivery_errors
  def index
    @errors = Pack::Report.failed_delivery(account_ids, 20)
  end
end

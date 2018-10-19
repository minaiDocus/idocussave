# -*- encoding : UTF-8 -*-
class Account::PreAssignmentsController < Account::OrganizationController
  # GET /account/organizations/:organization_id/pre_assignments
  def index
    @ibiza        = @organization.ibiza
    @exact_online = @organization.exact_online
  end
end

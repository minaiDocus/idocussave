# frozen_string_literal: true

class Account::PreAssignmentsController < Account::OrganizationController
  # GET /account/organizations/:organization_id/pre_assignments
  def index
    @ibiza = @organization.ibiza
  end
end

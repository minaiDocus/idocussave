# -*- encoding : UTF-8 -*-
class Account::PreAssignmentsController < Account::OrganizationController
  def index
    @ibiza = @organization.ibiza
  end
end

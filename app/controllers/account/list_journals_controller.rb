# frozen_string_literal: true

class Account::ListJournalsController < Account::OrganizationController
  before_action :load_customer
  before_action :redirect_to_current_step

  # GET /account/organizations/:organization_id/customers/:customer_id/list_journals
  def index
    @journals = @customer.account_book_types.order(name: :asc)
  end
end

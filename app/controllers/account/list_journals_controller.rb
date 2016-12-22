# -*- encoding : UTF-8 -*-
class Account::ListJournalsController < Account::OrganizationController
  before_filter :load_customer
  before_filter :redirect_to_current_step


  # GET /account/organizations/:organization_id/customers/:customer_id/list_journals
  def index
    @journals = @customer.account_book_types.order(name: :asc)
  end
end

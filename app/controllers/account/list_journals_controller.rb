# -*- encoding : UTF-8 -*-
class Account::ListJournalsController < Account::OrganizationController
  before_filter :load_customer
  before_filter :redirect_to_current_step

  def index
    @journals = @customer.account_book_types.asc(:name)
  end
end

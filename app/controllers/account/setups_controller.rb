# -*- encoding : UTF-8 -*-
class Account::SetupsController < Account::OrganizationController
  before_filter :load_customer

  def next
    if @customer.configured?
      redirect_to account_organization_customer_path(@organization, @customer)
    else
      next_configuration_step
    end
  end

  def previous
    if @customer.configured?
      redirect_to account_organization_customer_path(@organization, @customer)
    else
      previous_configuration_step
    end
  end
end

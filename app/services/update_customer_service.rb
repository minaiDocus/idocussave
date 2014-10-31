# -*- encoding : UTF-8 -*-
class UpdateCustomerService
  def initialize(customer, params)
    @customer = customer
    @params   = params
  end

  def execute
    @customer.assign_attributes(@params)
    if @customer.valid? && @customer.email_changed?
      @customer.reset_password_token = User.reset_password_token
      @customer.reset_password_sent_at = Time.now
      @customer.save
      WelcomeMailer.welcome_customer(@customer).deliver
    end
    @customer.save
  end
end

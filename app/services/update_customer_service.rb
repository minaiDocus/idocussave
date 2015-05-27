# -*- encoding : UTF-8 -*-
class UpdateCustomerService
  def initialize(customer, params)
    @customer = customer
    @params   = params
  end

  def execute
    @customer.assign_attributes(@params)
    if @customer.valid? && @customer.email_changed?
      encrypted_token, token = Devise.token_generator.generate(User, :reset_password_token)
      @customer.reset_password_token = token
      @customer.reset_password_sent_at = Time.now
      @customer.save
      WelcomeMailer.welcome_customer(@customer, encrypted_token).deliver
    end
    @customer.save
  end
end

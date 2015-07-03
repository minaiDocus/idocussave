# -*- encoding : UTF-8 -*-
class UpdateCustomerService
  def initialize(customer, params)
    @customer = customer
    @params   = params
  end

  def execute
    @customer.assign_attributes(@params)
    if @customer.valid? && @customer.email_changed?
      token, encrypted_token = Devise.token_generator.generate(User, :reset_password_token)
      @customer.reset_password_token = encrypted_token
      @customer.reset_password_sent_at = Time.now
      @customer.save
      WelcomeMailer.welcome_customer(@customer, token).deliver
    end
    @customer.save
  end
end

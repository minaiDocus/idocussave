class PaypalWrapper
  attr_reader :paypal_notify
  attr_accessor :gross
  cattr_accessor :config
  
  def initialize(request)
    @paypal_notify = Paypal::Notification.new(request.raw_post)
  end
  
  def valid?
    paypal_notify.completed? && gross == paypal_notify.params['mc_gross'].to_f && @@config["business_email"] == paypal_notify.params["business"] && @@config["currency"] == paypal_notify.params['mc_currency']
  end
  
  def item_id
    if paypal_notify.params['item_id'].present?
      return paypal_notify.params['item_id']
    else
      return paypal_notify.params['item_number']
    end
  end
  
  def self.url
    @@config['url']
  end
  
  def currency
    "EUR"
  end
end

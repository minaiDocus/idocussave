class McfSettings < ActiveRecord::Base
  attr_encrypted :access_token,            random_iv: true
  attr_encrypted :refresh_token,           random_iv: true
  attr_encrypted :access_token_expires_at, random_iv: true, type: :datetime

  belongs_to :organization

  validates :organization_id, presence: true, uniqueness: true

  def configured?
    access_token.present?
  end

  def ready?
    is_delivery_activated && configured?
  end

  def path
    delivery_path_pattern
  end

  def reset_tokens
    self.refresh_token           = nil
    self.access_token            = nil
    self.access_token_expires_at = nil
    save
  end

  def reset
    self.access_token            = nil
    self.refresh_token           = nil
    self.access_token_expires_at = nil
    self.delivery_path_pattern   = '/:year:month/:account_book/'
    self.is_delivery_activated   = true
    save
  end
end

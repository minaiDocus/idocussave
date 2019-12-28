class FirebaseToken < ApplicationRecord
  belongs_to :user

  validates_presence_of :name, :user

  def self.create_or_initialize(user, name, platform, version)
    firebase_token = user.firebase_tokens.find_by_name(name) || user.firebase_tokens.create(name: name, platform: "#{platform} - #{version}")
    
    firebase_token.update(last_registration_date: Time.now, platform: "#{platform} - #{version}") if firebase_token.present?
  end

  def valid_token?
    self.last_registration_date >= 7.days.ago
  end

  def delete_unless_valid
    self.destroy unless valid_token?
  end

  def update_last_sending_date
    self.update last_sending_date: Time.now
  end

end

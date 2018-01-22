class FirebaseToken < ActiveRecord::Base
  belongs_to :user
  validates_presence_of :name, :user

  def self.create_or_initialize(user, name, platform)
    firebase_token = user.firebase_tokens.find_by_name(name) || user.firebase_tokens.create(name: name, platform: platform)
    firebase_token.update last_registration_date: Time.now if firebase_token.present?
  end

  def valid_token?
    distance = (Time.now - self.last_registration_date) / 86400 #distance between dates in day (with 86400 seconds per day)
    return (distance > 7)? false : true #token is no long valid after 7 days
  end

  def delete_unless_valid
    self.destroy unless valid_token?
  end

  def update_last_sending_date
    self.update last_sending_date: Time.now
  end

end

class MobileConnexion < ApplicationRecord
  belongs_to :user

  scope :ios,     -> { where("platform = 'iOS'") }
  scope :android, -> { where("platform = 'android'") }
  scope :periode, -> (periode) { where(periode: periode) }

  validates_presence_of :user, :platform, :periode

  def self.log(user, platform, version)
    current_period = "#{Date.today.strftime("%Y").to_s}#{Date.today.strftime("%m").to_s}"
    today = "#{current_period}#{Date.today.strftime("%d").to_s}"

    connexion = user.mobile_connexions.where("platform = '#{platform}' AND DATE_FORMAT(date,'%Y%m%d') = #{today}").first

    if connexion
      connexion.daily_counter = (connexion.daily_counter || 0) + 1
      connexion.save
    else
      user.mobile_connexions.create(periode: current_period, platform: platform, version: version, date: Time.now, daily_counter: 1)
    end
  end
end
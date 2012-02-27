class BackgroundProcess
  ENV["RAILS_ENV"] = Rails.env
  
  def self.run
    `lib/daemons/maintenance_ctl start`
  end
  
  def self.status
    if `lib/daemons/maintenance_ctl status`.match(/no instances running/)
      false
    else
      true
    end
  end
end
# -*- encoding : UTF-8 -*-
class BackgroundProcess
  ENV["RAILS_ENV"] = Rails.env
  
  def self.run
    `bundle exec lib/daemons/maintenance_ctl start`
  end
  
  def self.status
    if `bundle exec lib/daemons/maintenance_ctl status`.match(/no instances running/)
      false
    else
      true
    end
  end
end

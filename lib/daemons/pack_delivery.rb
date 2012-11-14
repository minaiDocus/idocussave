# -*- encoding : UTF-8 -*-
#!/usr/bin/env ruby

# You might want to change this
ENV["RAILS_ENV"] ||= "production"

require File.dirname(__FILE__) + "/../../config/application"
Rails.application.require_environment!

$running = true
Signal.trap("TERM") do
  $running = false
end

while($running) do
  unless @filetime
    @filetime = File.atime(File.join(Rails.root,'tmp','stop_maintenance.txt')) rescue Time.now
  end

  Delivery::Queue.run

  time = Time.now
  while $running && (Time.now < (time + 60))
    sleep(1)
    new_filetime = File.atime(File.join(Rails.root,'tmp','stop_maintenance.txt')) rescue @filetime
    if @filetime < new_filetime
      $running = false
      puts "[stopped by user]"
    end
  end
end

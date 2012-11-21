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
  filepath = File.join(Rails.root,'tmp','stop_maintenance.txt')
  unless @filetime
    if File.exist? filepath
      @filetime = File.atime(filepath)
    else
      @filetime = Time.now
    end
  end

  Delivery::process('gdr')

  time = Time.now
  while $running && (Time.now < (time + 1))
    sleep(1)
    if File.exist? filepath
      new_filetime = File.atime(filepath)
    else
      new_filetime = @filetime
    end
    if @filetime < new_filetime
      $running = false
      puts "[stopped by user]"
    end
  end
end

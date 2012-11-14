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

  filesname = RegroupSheet::process
  data = []
  data += Pack.get_documents(filesname)
  filesname = Pack.get_file_from_numen
  data += Pack.get_documents(filesname)
  data.uniq!
  Pack.deliver_mail(data)
  ReminderEmail.deliver

  time = Time.now
  while $running && (Time.now < (time + 30.minutes))
    sleep(1)
    new_filetime = File.atime(File.join(Rails.root,'tmp','stop_maintenance.txt')) rescue @filetime
    if @filetime < new_filetime
      $running = false
      puts "[stopped by user]"
    end
  end
end

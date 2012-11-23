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
  filepath = File.join(Rails.root,'tmp','stop_worker.txt')
  unless @filetime
    if File.exist? filepath
      @filetime = File.atime(filepath)
    else
      @filetime = Time.now
    end
  end

  filesname = RegroupSheet::process
  data = []
  data += Pack.get_documents(filesname)
  filesname = Pack.get_file_from_numen
  data += Pack.get_documents(filesname)
  data.uniq!
  Pack::Report.fetch
  Pack.deliver_mail(data)
  ReminderEmail.deliver

  time = Time.now
  while $running && (Time.now < (time + 30.minutes))
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

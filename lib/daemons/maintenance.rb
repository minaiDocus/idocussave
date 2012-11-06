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
  data = RegroupSheet::process
  filesname = Pack.get_file_from_numen
  data += Pack.get_documents(filesname)
  data.uniq!
  Pack.deliver_mail(data)
  ReminderEmail.deliver
  
  sleep(1800)
end

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
  filesname = Pack.get_file_from_numen
  Pack.get_documents(filesname)
  ReminderEmail.deliver
  
  sleep(1800)
end

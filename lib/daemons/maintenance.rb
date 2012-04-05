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
    Pack.get_documents
    ReminderEmail.deliver
    Document.do_reprocess_styles
    Document.extract_content
    Document::Index.process
    
    sleep(1800)
end
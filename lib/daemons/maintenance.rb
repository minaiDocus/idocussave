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
  ok ||= false
  if Time.now.min != 0 or !ok
    sleep(60 - Time.now.min)
    ok = true
  end
  
  if ok
    Pack.get_documents
    Document.do_reprocess_styles
    Document.extract_content
    Document::Index.process
    ok = false
  end
end
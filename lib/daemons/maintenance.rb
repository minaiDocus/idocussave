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
  Document.do_reprocess_styles
  Document.extract_content
  
  User.all.each do |user|
    user.document_content_index = DocumentContentIndex.create unless user.document_content_index
    user.document_content_index.update_data!
  end
  
  sleep 1800
end
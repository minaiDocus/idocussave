VCR.configure do |c|
  c.cassette_library_dir = Rails.root.join('spec', 'vcr')
  c.allow_http_connections_when_no_cassette = true
  c.hook_into :webmock
end

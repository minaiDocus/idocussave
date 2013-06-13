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

@sleep_duration = [1.minute, 5.minutes, 30.minutes, 1.hour]
@sleep_type = 0

while($running) do
  filepath = File.join(Rails.root,'tmp','stop_return_labels_updater.txt')
  unless @filetime
    if File.exist? filepath
      @filetime = File.atime(filepath)
    else
      @filetime = Time.now
    end
  end

  begin
    result = ReturnLabels.fetch_data('ftp-clients.ppp-idc.com', 'idocus_pCompta', 'ipC2903!*', '/', 'ppp')
  rescue => e
    ::Airbrake.notify_or_ignore(
      :error_class   => e.class.name,
      :error_message => "#{e.class.name}: #{e.message}",
      :backtrace     => e.backtrace,
      :controller    => "return_labels_updater",
      :action        => "process",
      :cgi_data      => ENV
    )
    raise
  end

  if result
    @sleep_type = 0
  elsif @sleep_type < 4
    @sleep_type += 1
  else
    $running = false
  end

  time = Time.now
  while $running && (Time.now < (time + @sleep_duration[@sleep_type]))
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

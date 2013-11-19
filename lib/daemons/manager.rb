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
$continue = false
Signal.trap("USR1") do
  $continue = true
end

@program_name_prefix = '[idd]'
$PROGRAM_NAME = "#{@program_name_prefix}manager"

def with_error_handler(program_name, &block)
  begin
    yield
  rescue => e
    ::Airbrake.notify_or_ignore(
      :error_class   => e.class.name,
      :error_message => "#{e.class.name}: #{e.message}",
      :backtrace     => e.backtrace,
      :controller    => program_name,
      :action        => 'unknown',
      :cgi_data      => ENV
    )
    raise
  end
end

def with_state(program_name, sleep_duration, &block)
  $PROGRAM_NAME = "#{@program_name_prefix}#{program_name}[running]"
  with_error_handler(program_name, &block)
  $continue = false
  sleep_duration.times do |i|
    remaining_time = sleep_duration - i
    remaining_minutes = "%02d" % (remaining_time / 60)
    remaining_seconds = "%02d" % (remaining_time % 60)
    state = "sleeping #{remaining_minutes}:#{remaining_seconds}"
    $PROGRAM_NAME = "#{@program_name_prefix}#{program_name}[#{state}]"
    sleep(1)
    break unless $running
    break if $continue
  end
end

pids = []

[
  { name: 'ftp_fetcher',               sleep_duration: 10.minutes, cmd: Proc.new { DocumentFetcher.fetch('ftp.idocus.com', 'grevalis_petersbourg', 'idopetersB', '/', 'petersbourg') } },
  { name: 'bundler',                   sleep_duration: 30.seconds, cmd: Proc.new { PrepaCompta::DocumentBundler.bundle } },
  { name: 'processor',                 sleep_duration: 5.seconds,  cmd: Proc.new { DocumentProcessor.process } },
  { name: 'preassignment_fetcher',     sleep_duration: 30.seconds, cmd: Proc.new { Pack::Report.fetch } },
  { name: 'fiduceo_document_fetcher',  sleep_duration: 5.seconds,  cmd: Proc.new { FiduceoDocumentFetcher.fetch } },
  { name: 'delivery-dropbox_extended', sleep_duration: 10.seconds, cmd: Proc.new { Delivery.process('dbx') } },
  { name: 'delivery-dropbox_basic',    sleep_duration: 10.seconds, cmd: Proc.new { Delivery.process('dbb') } },
  { name: 'delivery-google_drive',     sleep_duration: 10.seconds, cmd: Proc.new { Delivery.process('gdr') } },
  { name: 'delivery-ftp',              sleep_duration: 10.seconds, cmd: Proc.new { Delivery.process('ftp') } },
  { name: 'delivery-box',              sleep_duration: 10.seconds, cmd: Proc.new { Delivery.process('box') } }
].each do |program|
  pids << fork do
    while($running)
      with_state program[:name], program[:sleep_duration] do
        program[:cmd].call
      end
    end
  end
end

while($running) do
  sleep(1)
end

pids.each do |pid|
  begin
    Process.kill 'TERM', pid
  rescue Errno::ESRCH, RangeError
  end
end

pids.count.times do
  begin
    Process.wait
  rescue Errno::ECHILD
  end
end

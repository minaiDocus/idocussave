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

def go_sleep(duration, program_name, state_prefix='sleeping')
  $continue = false
  duration.times do |i|
    remaining_time = duration - i
    remaining_minutes = "%02d" % (remaining_time / 60)
    remaining_seconds = "%02d" % (remaining_time % 60)
    state = "#{state_prefix} #{remaining_minutes}:#{remaining_seconds}"
    $PROGRAM_NAME = "#{@program_name_prefix}#{program_name}[#{state}]"
    sleep(1)
    break unless $running
    break if $continue
  end
end

def with_error_handler(program_name, &block)
  tries = 0
  begin
    yield
  rescue Net::POPAuthenticationError => e
    if tries < 3
      tries += 1
      go_sleep(tries.minutes, program_name, 'retrying in')
      retry
    else
      addresses = Array(Settings.notify_errors_to)
      if addresses.size > 0
        NotificationMailer.notify(addresses, "[iDocus][Email fetcher error] Net::POPAuthenticationError", e.message).deliver
      end
      $running = false
    end
  rescue => e
    ::Airbrake.notify_or_ignore(
      :error_class   => e.class.name,
      :error_message => "#{e.class.name}: #{e.message}",
      :backtrace     => e.backtrace,
      :controller    => program_name,
      :action        => 'unknown',
      :cgi_data      => ENV.to_hash
    )
    raise
  end
end

def with_state(program_name, sleep_duration, &block)
  $PROGRAM_NAME = "#{@program_name_prefix}#{program_name}[running]"
  with_error_handler(program_name, &block)
  go_sleep(sleep_duration, program_name) if $running
end

pids = []

[
  { name: 'ftp_fetcher',               sleep_duration: 10.minutes, cmd: Proc.new { DocumentFetcher.fetch('ftp.idocus.com', 'grevalis_petersbourg', 'idopetersB', '/', 'petersbourg') } },
  { name: 'bundler',                   sleep_duration: 30.seconds, cmd: Proc.new { PrepaCompta::DocumentBundler.bundle } },
  { name: 'processor',                 sleep_duration: 5.seconds,  cmd: Proc.new { DocumentProcessor.process } },
  { name: 'preassignment_fetcher',     sleep_duration: 30.seconds, cmd: Proc.new { Pack::Report.fetch } },
  { name: 'fiduceo_document_fetcher',  sleep_duration: 5.seconds,  cmd: Proc.new { FiduceoDocumentFetcher.fetch } },
  { name: 'operation_processor',       sleep_duration: 5.seconds,  cmd: Proc.new { OperationService.process } },
  { name: 'emailed_document_fetcher',  sleep_duration: 1.minute,   cmd: Proc.new { EmailedDocument.fetch_all } },
  { name: 'delivery-dropbox_extended', sleep_duration: 10.seconds, cmd: Proc.new { Delivery.process('dbx') } },
  { name: 'delivery-dropbox_basic',    sleep_duration: 10.seconds, cmd: Proc.new { Delivery.process('dbb') } },
  { name: 'delivery-google_drive',     sleep_duration: 10.seconds, cmd: Proc.new { Delivery.process('gdr') } },
  { name: 'delivery-ftp',              sleep_duration: 10.seconds, cmd: Proc.new { Delivery.process('ftp') } },
  { name: 'delivery-box',              sleep_duration: 10.seconds, cmd: Proc.new { Delivery.process('box') } },
  { name: 'delivery-knowings',         sleep_duration: 10.seconds, cmd: Proc.new { Delivery.process('kwg') } },
  { name: 'delivery-ibiza',            sleep_duration: 5.seconds,  cmd: Proc.new { PreAssignmentDeliveryService.execute } }
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

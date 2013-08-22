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
  filepath = File.join(Rails.root,'tmp','stop_maintenance.txt')
  unless @filetime
    if File.exist? filepath
      @filetime = File.atime(filepath)
    else
      @filetime = Time.now
    end
  end
  wakeup_filepath = File.join(Rails.root,'tmp','wakeup_maintenance.txt')
  unless @wakeup_filetime
    if File.exist? wakeup_filepath
      @wakeup_filetime = File.atime(wakeup_filepath)
    else
      @wakeup_filetime = Time.now
    end
  end

  begin
    filesname = RegroupSheet::process
    data = []
    data += Pack.get_documents(filesname)
    filesname = DematboxFile.prepare
    data += Pack.get_documents(filesname)
    filesname = Pack.get_file_from_ftp('193.168.63.12', 'depose', 'tran5fert', 'diadeis2depose/LIVRAISON')
    filesname += Pack.get_file_from_ftp('ftp-clients.ppp-idc.com', 'idocus_pCompta', 'ipC2903!*', '/', 'ppp')
    Pack.get_csv_files('ppp')
    data += Pack.get_documents(filesname)
    data.uniq!
    Pack::Report.fetch
    Pack.deliver_mail(data)
    ReminderEmail.deliver
  rescue => e
    ::Airbrake.notify_or_ignore(
      :error_class   => e.class.name,
      :error_message => "#{e.class.name}: #{e.message}",
      :backtrace     => e.backtrace,
      :controller    => "maintenance",
      :action        => "process",
      :cgi_data      => ENV
    )
    raise
  end

  time = Time.now
  wakeup = false
  while $running && (Time.now < (time + 30.minutes)) && wakeup == false
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
    if File.exist? wakeup_filepath
      new_wakeup_filetime = File.atime(wakeup_filepath)
    else
      new_wakeup_filetime = @wakeup_filetime
    end
    if @wakeup_filetime < new_wakeup_filetime
      puts "[waked up by user]"
      @wakeup_filetime = new_wakeup_filetime
      wakeup = true
    end
  end
end

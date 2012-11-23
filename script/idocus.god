rails_root = ENV['RAILS_ROOT'] || File.expand_path('../..', __FILE__)

%w(dbx dbb gdr box ftp).each do |service_prefix|
  God.watch do |w|
    w.name = "delivery[#{service_prefix}]"
    w.group = 'delivery'

    w.dir = rails_root
    w.behavior(:clean_pid_file)
    w.log = File.join(rails_root,"log/delivery_#{service_prefix}.log")

    w.start = "ruby #{File.join(rails_root,'lib/daemons/delivery.rb')} #{service_prefix}"
    w.stop = "touch #{File.join(rails_root,'tmp/stop_worker.txt')}"

    w.stop_timeout = 20

    w.keepalive

    w.start_if do |start|
      start.condition(:process_running) do |c|
        c.interval = 5
        c.running = false
      end
    end

    w.lifecycle do |on|
      on.condition(:flapping) do |c|
        c.to_state = [:start,:restart]
        c.times = 5
        c.within = 5.minutes
        c.transition = :unmonitored
        c.retry_in = 30.minutes
        c.retry_times = 3
        c.retry_within = 2.hours
      end
    end

    #w.transition(:up, :start) do |on|
    #  on.condition(:process_exits) do |c|
    #    c.notify = %w(developers watchers)
    #  end
    #end
  end
end

God::Contacts::Email.defaults do |d|
  d.from_email = 'notifier@idocus.com'
  d.from_name = 'Process watcher'
  d.delivery_method = :sendmail
end

God.contact(:email) do |c|
  c.name = 'lola'
  c.group = 'developers'
  c.to_email = 'lailol@directmada.com'
end

God.contact(:email) do |c|
  c.name = 'lola2'
  c.group = 'developers'
  c.to_email = 'lolalaikam@idocus.com'
end

God.contact(:email) do |c|
  c.name = 'florent'
  c.group = 'watchers'
  c.to_email = 'florent.tachot@idocus.com'
end

require 'sidekiq/scheduler'
scheduler_config_file = File.join(Rails.root, 'config', 'schedule.yml')
raise 'Schedule configuration file config/schedule.yml is missing.' unless File.exist?(scheduler_config_file)

if Rails.env.production?
  redis = { 
    db: 0 ,
    host: 'mymaster',
    role: :master,
    sentinels: [
      { host: '172.16.0.171', port: 26379 },
      { host: '172.16.0.172', port: 26379 },
      { host: '172.16.0.161', port: 26379 },
      { host: '172.16.0.161', port: 26379 },
      { host: '172.16.0.191', port: 26379 },
      { host: '172.16.0.192', port: 26379 }
    ],
    failover_reconnect_timeout: 20
  }
else
  redis = { url: "redis://localhost:6379/0" } 
end

$remote_lock = RemoteLock.new(RemoteLock::Adapters::Redis.new(Redis.new(redis)))

Sidekiq::Extensions.enable_delay!

Sidekiq.configure_server do |config|
  if Rails.env.production?
    config.on(:startup) do
      Sidekiq.schedule = YAML.load_file(scheduler_config_file)
      Sidekiq::Scheduler.reload_schedule!
    end
  end

  config.redis = redis
end

Sidekiq.configure_client do |config|
  config.redis = redis
end

require 'sidekiq/scheduler'
scheduler_config_file = File.join(Rails.root, 'config', 'schedule.yml')
raise 'Schedule configuration file config/schedule.yml is missing.' unless File.exist?(scheduler_config_file)

database = case Rails.env
  when 'production'
    0
  when 'staging'
    1
  when 'development'
    2
  when 'test'
    3
  when 'sandbox'
    4
  end

redis = { url: "redis://localhost:6379/#{database}" }

$remote_lock = RemoteLock.new(RemoteLock::Adapters::Redis.new(Redis.new(redis)))

Sidekiq.configure_server do |config|
  config.on(:startup) do
    Sidekiq.schedule = YAML.load_file(scheduler_config_file)
    Sidekiq::Scheduler.reload_schedule!
  end

  config.redis = redis
end

Sidekiq.configure_client do |config|
  config.redis = redis
end

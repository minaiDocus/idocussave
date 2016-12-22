require 'sidekiq/scheduler'
scheduler_config_file = File.join(Rails.root, 'config', 'schedule.yml')
raise 'Schedule configuration file config/schedule.yml is missing.' unless File.exist?(scheduler_config_file)


Sidekiq.configure_server do |config|
  config.on(:startup) do
    Sidekiq.schedule = YAML.load_file(scheduler_config_file)
    Sidekiq::Scheduler.reload_schedule!
  end
end
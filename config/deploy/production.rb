set :deploy_to, "/home/grevalis/www/idocus/production"

namespace :delayed_job do
  desc "Start delayed_job process"
  task :start, :roles => :app do
    run "cd #{current_path}; RAILS_ENV=#{rails_env} script/delayed_job -n 20 start"
  end

  desc "Stop delayed_job process"
  task :stop, :roles => :app do
    run "cd #{current_path}; RAILS_ENV=#{rails_env} script/delayed_job stop"
  end

  desc "Restart delayed_job process"
  task :restart, :roles => :app do
    delayed_job.stop
    delayed_job.start
  end
end

namespace :worker do
  desc "Start worker process"
  task :start, :roles => :app do
    run "cd #{current_path}; RAILS_ENV=#{rails_env} god -c script/idocus.god"
    run "cd #{current_path}; RAILS_ENV=#{rails_env} lib/daemons/maintenance_ctl start"
  end

  desc "Stop worker process"
  task :stop, :roles => :app do
    run "cd #{current_path}; touch tmp/stop_worker.txt"
    run "cd #{current_path}; touch tmp/stop_maintenance.txt"
    run "cd #{current_path}; god terminate"
  end
end

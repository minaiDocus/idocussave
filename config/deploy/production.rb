set :deploy_to, "/home/grevalis/www/idocus/production"

namespace :delayed_job do
  desc "Start delayed_job process"
  task :start, :roles => :app do
    run "cd #{current_path}; RAILS_ENV=#{rails_env} script/delayed_job -n 5 start"
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

namespace :manager do
  desc "Start manager"
  task :start, :roles => :app do
    run "cd #{current_path}; RAILS_ENV=#{rails_env} bundle exec lib/daemons/manager_ctl start"
  end

  desc "Stop manager"
  task :stop, :roles => :app do
    file_path = "#{current_path}/log/manager.rb.pid"
    run "if [ -e #{file_path} ]; then kill -TERM $(cat #{file_path}); fi"
  end
end

set :deploy_to, "/home/grevalis/www/idocus/staging"
set :branch, $1 if `git branch` =~ /\* (\S+)\s/m
set :rails_env, "staging"
set :rack_env, "staging"

namespace :git do
  desc "Push code to origin"
  task :push, :roles => :app do
    %x(git push origin #{branch})
  end
end

namespace :manager do
  desc "Start manager"
  task :start, :roles => :app do
    run "cd #{release_path}; RAILS_ENV=#{rails_env} bundle exec lib/daemons/manager_ctl start"
  end

  desc "Stop manager"
  task :stop, :roles => :app do
    file_path = "#{current_path}/log/manager.rb.pid"
    run "if [ -e #{file_path} ]; then kill -TERM $(cat #{file_path}); fi"
  end
end

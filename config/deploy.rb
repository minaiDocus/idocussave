set :rvm_ruby_string, '1.9.3'
require "rvm/capistrano"

default_run_options[:pty] = true
#ssh_options[:forward_agent] = true

set :runner, "rails"
set :user, "grevalis"
set :password, "grevidoc"
set :scm_username, "grevalis"
set :scm_password, "grevidoc"
set :use_sudo, false
set :rails_env, "production"

set :application, "idocus"
role :app, "grevalis.alwaysdata.net"
set :deploy_to, "/home/grevalis/www/idocus"

set :keep_releases, 5

set :repository, "git@github.com:ftachot/idocus.git"
set :scm, "git"
set :branch, "master"
set :deploy_via, :remote_cache
set :repository_cache, "git_cache"
set :copy_exclude, [".svn", ".DS_Store", ".git"]

before "deploy", "deploy:setup", "shared:mkdir"
before "deploy:update", "git:push"
after "deploy:finalize_update", "shared:config"
before "deploy:symlink", "shared:symlink"
after "deploy", "deploy:cleanup"

namespace :shared do
  desc "Make symlink"
  task :symlink do
    run "ln -nfs #{shared_path}/config/mongoid.yml #{release_path}/config/mongoid.yml"
    run "ln -nfs #{shared_path}/config/initializers/address_delivery_list.rb #{release_path}/config/initializers/address_delivery_list.rb"
    run "ln -nfs #{shared_path}/config/initializers/error_notification.rb #{release_path}/config/initializers/error_notification.rb"
    run "ln -nfs #{shared_path}/config/initializers/fix_ssl.rb #{release_path}/config/initializers/fix_ssl.rb"
    run "ln -nfs #{shared_path}/config/initializers/invoice_config.rb #{release_path}/config/initializers/invoice_config.rb"
    run "ln -nfs #{shared_path}/public/system #{release_path}/public/system"
    run "ln -s #{shared_path}/data #{release_path}/data"
    run "ln -s #{shared_path}/files #{release_path}/files"
  end

  desc "Create necessary directories"
  task :mkdir do
    run "mkdir -p #{shared_path}/config/initializers"
    run "mkdir -p #{shared_path}/public/system"
    run "mkdir -p #{current_release}/tmp"
    run "mkdir -p #{shared_path}/data"
    run "mkdir -p #{shared_path}/files/tmp/uploads"
    run "mkdir -p #{shared_path}/files/kit"
    run "mkdir -p #{shared_path}/files/attachments/archives"
  end

  desc "Prepare config files"
  task :config do
    if File.exist? "#{shared_path}/config/initializers/error_notification.rb"
      run "rm #{release_path}/config/initializers/error_notification.rb"
    else
      run "mv #{release_path}/config/initializers/error_notification.rb #{shared_path}/config/initializers"
    end
    if File.exist? "#{shared_path}/config/initializers/invoice_config.rb"
      run "rm #{release_path}/config/initializers/invoice_config.rb"
    else
      run "mv #{release_path}/config/initializers/invoice_config.rb #{shared_path}/config/initializers"
    end
    if File.exist? "#{shared_path}/config/initializers/address_delivery_list.rb"
      run "rm #{release_path}/config/initializers/address_delivery_list.rb"
    end
  end
end

namespace :mod_rails do
  desc "Restart the application altering tmp/restart.txt for mod_rails."
  task :restart, :roles => :app do
    run "touch #{current_release}/tmp/restart.txt"
  end
end

namespace :deploy do
  %w(start restart).each { |name| task name, :roles => :app do mod_rails.restart end }
end

namespace :git do
  desc "Push code to origin"
  task :push, :roles => :app do
    %x(git push origin master)
  end
end

namespace :delayed_job do
  desc "Start delayed_job process"
  task :start, :roles => :app do
    run "cd #{current_path}; RAILS_ENV=#{rails_env} script/delayed_job -i=1 --queues='documents thumbs,documents content' start"
    run "cd #{current_path}; RAILS_ENV=#{rails_env} script/delayed_job -i=2 --queues='documents thumbs,documents content' start"
    run "cd #{current_path}; RAILS_ENV=#{rails_env} script/delayed_job -i=3 --queues='documents thumbs,documents content' start"
    run "cd #{current_path}; RAILS_ENV=#{rails_env} script/delayed_job -i=4 --queues='documents thumbs,documents content' start"
    run "cd #{current_path}; RAILS_ENV=#{rails_env} script/delayed_job -i=5 --queues='documents thumbs,documents content' start"
    run "cd #{current_path}; RAILS_ENV=#{rails_env} script/delayed_job -i=6 --queue='delivery' start"
    run "cd #{current_path}; RAILS_ENV=#{rails_env} script/delayed_job -i=7 --queue='delivery' start"
    run "cd #{current_path}; RAILS_ENV=#{rails_env} script/delayed_job -i=8 --queue='delivery' start"
    run "cd #{current_path}; RAILS_ENV=#{rails_env} script/delayed_job -i=9 --queue='delivery' start"
    run "cd #{current_path}; RAILS_ENV=#{rails_env} script/delayed_job -i=10 --queue='delivery' start"
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

namespace :maintenance do
  desc "Start maintenance process"
  task :start, :roles => :app do
    run "cd #{current_path}; RAILS_ENV=#{rails_env} lib/daemons/maintenance_ctl start"
    run "cd #{current_path}; RAILS_ENV=#{rails_env} lib/daemons/pack_delivery_ctl start"
  end

  desc "Stop maintenance process"
  task :stop, :roles => :app do
    run "cd #{current_path}; RAILS_ENV=#{rails_env} lib/daemons/maintenance_ctl stop"
    run "cd #{current_path}; RAILS_ENV=#{rails_env} lib/daemons/pack_delivery_ctl stop"
  end

  desc "Restart maintenance process"
  task :restart, :roles => :app do
    run "cd #{current_path}; RAILS_ENV=#{rails_env} lib/daemons/maintenance_ctl restart"
    run "cd #{current_path}; RAILS_ENV=#{rails_env} lib/daemons/pack_delivery_ctl restart"
  end
end
